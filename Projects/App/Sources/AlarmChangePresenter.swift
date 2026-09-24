import Domain
import Foundation
import UIKit
import os

/// 알람 시각 **변경을 사용자에게 알리는** 일만 한다 — 판정(`EvaluateAlarmChangeUseCase`)
/// 결과를 받아 세 채널로 분기한다: ① Live Activity ② 로컬 노티(LA 도달 불가 폴백)
/// ③ 인앱(`AlarmChangeEvents` → 홈 배너 강조·토스트).
///
/// 이전에는 동기화 트리거와 한 타입에 있었다(575줄, 프로토콜 3개 동시 구현). 트리거를
/// 모으는 일과 변경을 표출하는 일은 같은 세션을 필요로 했을 뿐 서로를 알 필요가 없다 —
/// 세션을 `AlarmSessionStore`가 소유하게 되자 분리가 가능해졌다.
///
/// 이 타입의 모든 표출은 **실패 무해**다. LA·노티 포트가 non-throwing이라 알람 자체에
/// 영향을 줄 구조가 없다(알람 재스케줄은 표출보다 앞서 끝나 있다).
@MainActor
final class AlarmChangePresenter: AlarmChangeEvents {
    private let evaluateChangeUseCase: any EvaluateAlarmChangeUseCase
    /// LA 표출 경로 — non-throwing 계약(어댑터가 실패 흡수)이라 이 훅의 어떤 실패도 무해하다.
    private let liveActivity: any LastTrainChangeAlerting
    /// dismiss 폴백 채널 — 유저가 LA를 지운 뒤의 변경 alert를 로컬 노티로 대신한다.
    /// 발송도 non-throwing(권한 없으면 조용히 no-op) — 여기서 권한을 요청하는 일은 절대 없다.
    private let localNotification: any LocalNotificationPort
    /// sessionEnded 시 로컬 알람 취소용 — 등록/갱신 UseCase와 같은 스케줄러를 공유한다.
    private let alarmScheduler: any AlarmScheduler
    /// 도보 초의 출처 — 알람 시각 계산이 등록/refresh와 같은 기준을 타야 한다(이중 시각 금지).
    private let sessionStore: AlarmSessionStore
    /// 표출 채널 분기용 앱 활성 판정 — UIApplication 직접 참조를 걷어내 테스트가 상태를
    /// 주입한다. 분기 의미(포그라운드 = 인앱 채널 단독)는 불변.
    private let isAppActive: @MainActor () -> Bool
    private let now: @Sendable () -> Date
    private static let logger = Logger(subsystem: "com.atcha.iOS.v2", category: "AlarmChange")

    /// "⚠ 당겨짐" 배지 유지 시간 — 정책: 표출 시점 + 10분.
    private static let changeBadgeDuration: TimeInterval = 600

    /// 변경 판정 구독자 — 세션 스트림과 달리 **replay 없음**(과거 변경이 재구독 시 재발화 금지).
    /// "상태는 replay-1, 사건은 replay 없음"의 사건 쪽이다.
    private var changeSubscribers: [UUID: AsyncStream<AlarmChangeVerdict>.Continuation] = [:]
    /// "⚠ 당겨짐" 배지의 현재 만료 시각 — 조용한 갱신(unchanged/delayed)이 배지를 10분
    /// 정책보다 일찍 지우지 않도록 보존한다. **세션 상태가 아니라 표출 상태**라 여기 둔다.
    private var changeBadgeExpiry: Date?

    init(
        evaluateChangeUseCase: any EvaluateAlarmChangeUseCase,
        liveActivity: any LastTrainChangeAlerting,
        localNotification: any LocalNotificationPort,
        alarmScheduler: any AlarmScheduler,
        sessionStore: AlarmSessionStore,
        isAppActive: @escaping @MainActor () -> Bool = {
            UIApplication.shared.applicationState == .active
        },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.evaluateChangeUseCase = evaluateChangeUseCase
        self.liveActivity = liveActivity
        self.localNotification = localNotification
        self.alarmScheduler = alarmScheduler
        self.sessionStore = sessionStore
        self.isAppActive = isAppActive
        self.now = now
    }

    /// 세션이 아는 도보 초로 알람 시각을 계산한다 — `AlarmSession.fireDate`가 도보 초를
    /// 읽는 유일한 경로이므로, 세션이 없을 때만 버퍼 폴백을 쓴다.
    private func alarmFireDate(departureTime: Date) -> Date {
        AlarmTiming.alarmFireDate(
            departureTime: departureTime,
            firstWalkSeconds: sessionStore.current?.local.firstWalkSeconds
        )
    }

    /// 계정이 바뀌면 이전 계정의 표출 상태가 새 계정에 남으면 안 된다.
    func reset() {
        changeBadgeExpiry = nil
    }

    /// 로컬 만료 확정 시 호출 — 표출만 하고 세션 기록은 손대지 않는다(Store가 이미 했다).
    func presentLocalExpiry(of session: AlarmSession) async {
        await presentSessionEnded(previous: session.server, now: now())
        yieldChange(.sessionEnded)
    }

    /// 판정 → 채널 분기. LA 호출은 전부 실패 무해(포트가 non-throwing) — 알람에 영향 없음.
    func propagateChange(previous: AlarmInfo?, latest: AlarmInfo) async {
        let now = self.now()
        // 첫 수신(이전 값 없음)은 비교 대상이 없다 — unchanged 취급.
        let verdict = previous.map {
            evaluateChangeUseCase.execute(previous: $0, latest: latest, now: now)
        } ?? AlarmChangeVerdict.unchanged

        switch verdict {
        case .unchanged:
            // 변경 없음 — 조용한 상태 갱신 1회만(긴급도 색 재평가 목적). 배지·alert·yield 없음.
            if let state = activityState(for: latest, now: now) {
                await liveActivity.update(state: state, alert: nil)
            }

        case .delayed:
            // 늦춰짐 — 새 시각·재평가 긴급도로 조용한 업데이트. 배지 없음.
            if let state = activityState(for: latest, now: now) {
                await liveActivity.update(state: state, alert: nil)
            }
            yieldChange(verdict)

        case let .advanced(by: delta, actionable: true):
            await presentAdvanced(previous: previous, latest: latest, delta: delta, now: now)
            yieldChange(verdict)

        case .advanced(by: _, actionable: false):
            // 못 타게 됨 — LA를 실패 상태(missed)로 전환하고 '막차가 지나갔어요'를 알린다.
            await presentMissed(latest: latest, now: now)
            yieldChange(verdict)

        case .sessionEnded:
            // 운행 종료·경로 소멸 — LA 최종 상태 종료 + 로컬 알람 취소.
            // 배너 정리는 changes yield를 받은 홈의 몫.
            // 로컬 기록 정리는 Store가 `.ended` outcome에서 이미 했다.
            await presentSessionEnded(previous: previous, now: now)
            yieldChange(verdict)
        }
    }

    /// 앞당겨짐(actionable) 표출 — 새 알람 시각과 앱 상태로 alert 채널을 고른다.
    private func presentAdvanced(
        previous: AlarmInfo?,
        latest: AlarmInfo,
        delta: TimeInterval,
        now: Date
    ) async {
        guard let departure = latest.departureTime else { return }
        let alarmTime = alarmFireDate(departureTime: departure)
        let badgeExpiry = now.addingTimeInterval(Self.changeBadgeDuration)
        // 조용한 후속 갱신(unchanged/delayed)이 배지를 10분보다 일찍 지우지 않도록 보존한다.
        changeBadgeExpiry = badgeExpiry

        guard alarmTime > now else {
            // 새 알람 시각이 이미 과거(출발은 미래) — 마지노선 침범. 원래 울렸어야 할 알람
            // 시점이 지나 있으므로 조용한 채널로는 늦다: 백그라운드면 즉시 최후통첩.
            let ultimatumState = LastTrainActivityState(
                departureTime: departure,
                alarmTime: alarmTime,
                urgency: .imminent,
                changeBadgeExpiry: badgeExpiry,
                phase: .active
            )
            if isAppActive() {
                // 포그라운드 — LA alert 소리·로컬 노티 없이 조용한 상태 갱신만(Phase 15
                // 이중 알림 제거). 사용자 주의는 인앱 채널(changes 스트림 → 배너 강조 +
                // 토스트)이 단독으로 맡는다 — 일반 advanced·missed 분기와 동일 구조.
                await liveActivity.update(state: ultimatumState, alert: nil)
                return
            }
            let alert = (
                title: LastTrainChangeMessages.ultimatumTitle,
                body: LastTrainChangeMessages.ultimatumBody(latestDeparture: departure)
            )
            if await liveActivity.isAlertReachable {
                await liveActivity.update(state: ultimatumState, alert: alert)
            } else {
                // 도달 불가 폴백(Phase 12→15 확대) — dismissed·activity 없음·LA 비활성
                // 전부 로컬 노티로 갈아탄다. push-to-start 재생성은 하지 않는다(정책 불변).
                // 피기백 시점엔 앱이 깨어 있으므로 서버 무관여 로컬 노티로 같은 문구를 보낸다.
                await localNotification.post(title: alert.title, body: alert.body)
            }
            return
        }

        let state = LastTrainActivityState(
            departureTime: departure,
            alarmTime: alarmTime,
            urgency: LastTrainUrgency.forTimeRemaining(alarmTime.timeIntervalSince(now)),
            changeBadgeExpiry: badgeExpiry,
            phase: .active
        )
        if isAppActive() {
            // 포그라운드 — LA alert 생략(조용한 업데이트 + 배지). 사용자 주의는 인앱 채널
            // (changes 스트림 → 홈 배너 강조 + 토스트)이 맡는다. 이중 알림 방지.
            await liveActivity.update(state: state, alert: nil)
            return
        }

        // 백그라운드 — 행동 중심 문구를 잠금화면에 싣는다.
        let minutesEarlier = max(1, Int((delta / 60).rounded(.up)))
        // advanced(by:)의 delta = 이전 출발 − 새 출발. 이전 값이 비어 있으면 새 시각 + delta로 복원.
        let previousDeparture = previous?.departureTime ?? departure.addingTimeInterval(delta)
        let alert = (
            title: LastTrainChangeMessages.advancedAlertTitle(minutesEarlier: minutesEarlier),
            body: LastTrainChangeMessages.advancedAlertBody(from: previousDeparture, to: departure)
        )
        if await liveActivity.isAlertReachable {
            // 잠금화면 alert + "당겨짐" 배지(만료 now+10분).
            await liveActivity.update(state: state, alert: alert)
        } else {
            // 도달 불가 폴백(Phase 12→15 확대) — LA alert 대신 같은 행동 중심 문구의
            // 로컬 노티. push-to-start 재생성 금지(정책) — 지워진 LA를 되살리지 않는다.
            await localNotification.post(title: alert.title, body: alert.body)
        }
    }

    /// 못 탐(advanced, actionable: false) 표출 — LA를 실패 상태(missed)로 전환한다.
    /// 알람은 손대지 않는다: 과거 fireDate 재스케줄은 RefreshAlarmUseCase가 이미 걸렀고,
    /// 이미 울렸거나 임박한 알람을 지우는 것은 인지 기회만 줄인다.
    private func presentMissed(latest: AlarmInfo, now: Date) async {
        // actionable=false 판정은 departureTime이 있을 때만 나온다(없으면 sessionEnded).
        guard let departure = latest.departureTime else { return }
        // 실패 상태로 내려가면 "당겨짐" 배지는 의미를 잃는다 — 보존 기록도 접는다.
        changeBadgeExpiry = nil
        let state = LastTrainActivityState(
            departureTime: departure,
            alarmTime: alarmFireDate(departureTime: departure),
            urgency: .imminent,
            changeBadgeExpiry: nil,
            phase: .missed
        )
        // TODO(#9 임시 — 문구만): 대안 제시 데이터(심야버스·첫차 등) 확보 시 본문에 대안 안내를 싣는다.
        let alert = (
            title: LastTrainChangeMessages.missedTitle,
            body: LastTrainChangeMessages.missedBody(latestDeparture: departure)
        )
        if isAppActive() {
            // 포그라운드 — 상태 전환만 조용히. 사용자 주의는 인앱 채널이 맡는다(이중 알림 방지).
            await liveActivity.update(state: state, alert: nil)
        } else if await liveActivity.isAlertReachable {
            await liveActivity.update(state: state, alert: alert)
        } else {
            // 도달 불가 폴백(Phase 12→15 확대) — push-to-start 재생성 금지, 같은 문구의
            // 로컬 노티로 대신한다.
            await localNotification.post(title: alert.title, body: alert.body)
        }
    }

    /// 운행 종료·경로 소멸(sessionEnded) 표출 — LA를 최종 상태(serviceEnded)로 내리고
    /// 로컬 알람을 취소한다. 서버 측 알람 취소는 부르지 않는다 — 경로 소멸은 서버 재계산
    /// 결과 그 자체라 이미 반영돼 있다.
    /// TODO: [미확정] 서버가 종료 후에도 세션을 남겨 두는 스펙으로 확정되면 취소 API 연동을 재검토한다.
    private func presentSessionEnded(previous: AlarmInfo?, now: Date) async {
        // 더는 울리면 안 되는 것이 정책의 핵심 — 표출(LA 종료)보다 알람 취소를 먼저 한다.
        await alarmScheduler.cancelAlarm()
        changeBadgeExpiry = nil

        // sessionEnded 응답에는 departureTime이 없다 — 종료 시각 정보용으로 직전 스냅샷
        // (previous = 갱신 전 서버 값)의 마지막 출발 시각을 쓰고, 그것도 없으면 now.
        let departure = previous?.departureTime ?? now
        // 유저가 이미 LA를 지웠으면 end는 no-op — 종료는 행동을 요구하지 않으므로
        // 로컬 노티 폴백도 없다(배너 정리는 changes 스트림을 받은 홈이 한다).
        await liveActivity.end(final: LastTrainActivityState(
            departureTime: departure,
            alarmTime: alarmFireDate(departureTime: departure),
            // 위젯은 serviceEnded phase 키로 그린다 — urgency는 종료 화면에선 의미 없는 방어값.
            urgency: .imminent,
            changeBadgeExpiry: nil,
            phase: .serviceEnded
        ))
    }

    /// 갱신된 AlarmInfo → LA 상태. departureTime이 없으면(세션 종료 등) 만들 수 없다.
    /// 조용한 갱신도 살아 있는 "당겨짐" 배지는 그대로 싣는다 — 10분 정책 보존(Phase 14).
    private func activityState(for info: AlarmInfo, now: Date) -> LastTrainActivityState? {
        guard let departure = info.departureTime else { return nil }
        let alarmTime = alarmFireDate(departureTime: departure)
        if let badgeExpiry = changeBadgeExpiry, badgeExpiry <= now {
            changeBadgeExpiry = nil // 만료된 배지 기록은 정리한다.
        }
        return LastTrainActivityState(
            departureTime: departure,
            alarmTime: alarmTime,
            urgency: LastTrainUrgency.forTimeRemaining(alarmTime.timeIntervalSince(now)),
            changeBadgeExpiry: changeBadgeExpiry,
            phase: .active
        )
    }

    private func yieldChange(_ verdict: AlarmChangeVerdict) {
        for continuation in changeSubscribers.values {
            continuation.yield(verdict)
        }
    }

    // MARK: - AlarmChangeEvents

    /// updates()와 달리 replay 없음 — 변경 알림은 상태가 아니라 사건이라,
    /// 재구독 시 과거 판정이 다시 발화하면(배너 강조·토스트 반복) 안 된다.
    nonisolated func changes() -> AsyncStream<AlarmChangeVerdict> {
        AsyncStream { continuation in
            let id = UUID()
            Task { @MainActor in
                self.changeSubscribers[id] = continuation
            }
            continuation.onTermination = { _ in
                Task { @MainActor in
                    self.changeSubscribers.removeValue(forKey: id)
                }
            }
        }
    }
}
