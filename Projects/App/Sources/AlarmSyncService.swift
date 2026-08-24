import Domain
import Foundation
import UIKit
import os

/// 서버발 알람 시각 갱신의 단일 진입점. 앱 시작(인증 부트스트랩 직후)·포그라운드
/// 복귀·사일런트 푸시 3경로가 전부 여기의 `RefreshAlarmUseCase` 호출 한 곳으로
/// 모인다 — 시각 변경 시 재스케줄은 UseCase 내부 정책이고, 성공 결과는
/// `AlarmSyncEvents` 스트림으로 구독자(HomeViewModel)에게 전파돼 배너를 갱신한다.
///
/// Phase 11 피기백: 갱신 성공 뒤 전/후 AlarmInfo를 판정(`EvaluateAlarmChangeUseCase`)해
/// ① LA 채널(당겨짐 alert / 늦춰짐 조용한 갱신)과 ② 인앱 채널(`AlarmChangeEvents` →
/// 홈 배너 강조·토스트)을 덧붙인다. 알람 재스케줄은 `RefreshAlarmUseCase.execute()` 안에서
/// 이미 끝난 뒤라(반환 = 재스케줄 완료) LA·인앱 표출 실패가 알람을 막을 구조 자체가 없다.
///
/// Phase 12 폴백·종료: ③ 유저가 LA를 스와이프로 지운 기록(`isDismissedByUser`)이 있으면
/// 백그라운드 alert 채널을 로컬 노티(같은 문구)로 갈아탄다 — 피기백 시점엔 앱이 깨어 있으므로
/// 서버 무관여로 가능하고, push-to-start 재생성은 하지 않는다(지운 의사 존중).
/// ④ advanced(actionable: false)는 LA를 missed 상태로, sessionEnded는 serviceEnded 최종
/// 상태로 내리고 로컬 알람을 취소한다. 배너 정리는 changes 스트림을 받은 홈의 몫.
///
/// Phase 13 클라 자체 만료: sync 진입 시 보유 세션이 유예(출발+60초)를 넘겼으면 만료
/// 후보로 잡고, refresh 결과와 무관하게 로컬 sessionEnded 처리한다 — 단 refresh가
/// 성공해 **미래 출발 시각**을 반환하면 서버 우선(만료 취소, 정상 갱신 경로).
/// 만료 확정 세션은 기록해 이후 refresh가 같은 과거 세션으로 배너를 되살리지 못하게
/// 한다(홈의 미래 시각 가드가 1차 방어, 이 기록이 2차).
// Sendable 프로토콜(AlarmSyncEvents 등) 채택이 기본 MainActor 격리를 nonisolated로
// 추론시키므로 명시한다 — 상태(subscribers 등)는 전부 메인 액터에서만 만진다.
@MainActor
final class AlarmSyncService: AlarmSyncEvents, AlarmChangeEvents {
    private let refreshAlarmUseCase: any RefreshAlarmUseCase
    private let evaluateChangeUseCase: any EvaluateAlarmChangeUseCase
    /// LA 표출 경로 — non-throwing 계약(어댑터가 실패 흡수)이라 이 훅의 어떤 실패도 무해하다.
    private let liveActivity: any LastTrainChangeAlerting
    /// dismiss 폴백 채널(Phase 12) — 유저가 LA를 지운 뒤의 변경 alert를 로컬 노티로 대신한다.
    /// 발송도 non-throwing(권한 없으면 조용히 no-op) — 여기서 권한을 요청하는 일은 절대 없다.
    private let localNotification: any LocalNotificationPort
    /// sessionEnded 시 로컬 알람 취소용(Phase 12) — 등록/갱신 UseCase와 같은 스케줄러를 공유한다.
    private let alarmScheduler: any AlarmScheduler
    private static let logger = Logger(subsystem: "com.atcha.iOS.v2", category: "AlarmSync")

    /// "⚠ 당겨짐" 배지 유지 시간 — 정책: 표출 시점 + 10분.
    private static let changeBadgeDuration: TimeInterval = 600

    private var subscribers: [UUID: AsyncStream<AlarmInfo>.Continuation] = [:]
    /// 변경 판정 구독자 — updates()와 달리 **replay 없음**(과거 변경이 재구독 시 재발화 금지).
    private var changeSubscribers: [UUID: AsyncStream<AlarmChangeVerdict>.Continuation] = [:]
    /// 구독 전에 끝난 동기화를 놓치지 않기 위한 replay-1. 홈은 앱 시작 동기화와
    /// 거의 동시에 구독하므로 순서에 기대지 않는다. 변경 판정의 "이전 값"이기도 하다.
    private var lastInfo: AlarmInfo?
    /// Phase 13 만료 2차 방어 — 로컬 만료를 확정한 세션. 이후 refresh가 같은 routeId의
    /// 과거 세션을 반환해도 무시한다(미래 출발이 오면 서버 우선으로 해제).
    private var locallyExpiredSession: AlarmInfo?
    /// 진행 중 동기화 — 트리거가 겹치면(예: 앱 시작 직후 포그라운드 노티) 합류한다.
    private var inFlight: Task<AlarmInfo?, Never>?
    private var foregroundObserver: (any NSObjectProtocol)?

    // 앱 수명 객체(조합 루트 소유) — 해제 경로가 없어 관찰 해지/태스크 취소 정리가 없다.
    init(
        refreshAlarmUseCase: any RefreshAlarmUseCase,
        evaluateChangeUseCase: any EvaluateAlarmChangeUseCase,
        liveActivity: any LastTrainChangeAlerting,
        localNotification: any LocalNotificationPort,
        alarmScheduler: any AlarmScheduler
    ) {
        self.refreshAlarmUseCase = refreshAlarmUseCase
        self.evaluateChangeUseCase = evaluateChangeUseCase
        self.liveActivity = liveActivity
        self.localNotification = localNotification
        self.alarmScheduler = alarmScheduler
    }

    /// 인증 부트스트랩 완료 후 1회 호출: 즉시 동기화(앱 시작 경로) + 포그라운드
    /// 관찰 시작. 그 전의 포그라운드 전환은 무시된다 — 세션 없이 refresh를 쏘지 않는다.
    func activate() {
        guard foregroundObserver == nil else { return }
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIScene.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Sendable 클로저 → 메인 액터 복귀. 서비스는 앱과 수명이 같아 강한 캡처로 충분하다.
            Task { @MainActor in _ = await self.sync() }
        }
        Task { _ = await sync() }
    }

    /// 사일런트 푸시(content-available=1) 경로 — 백그라운드 fetch 결과 매핑까지 담당.
    func syncFromPush() async -> UIBackgroundFetchResult {
        await sync() != nil ? .newData : .failed
    }

    /// 3경로 공용 동기화. 실패는 스트림에 흘리지 않는다 — 구독자는 상태를 유지하고,
    /// 다음 트리거(포그라운드·푸시)가 자연 재시도가 된다.
    @discardableResult
    private func sync() async -> AlarmInfo? {
        if let inFlight {
            return await inFlight.value
        }
        Self.logger.info("알람 동기화 시작")
        // Phase 13 선행 판정 — 확정은 refresh 결과를 본 뒤(미래 출발이면 서버 우선 취소).
        let expiryCandidate = expireLocallyIfNeeded(now: Date())
        let task = Task { [refreshAlarmUseCase] () -> AlarmInfo? in
            do {
                return try await refreshAlarmUseCase.execute()
            } catch {
                Self.logger.info("알람 동기화 실패(상태 유지): \(error)")
                return nil
            }
        }
        inFlight = task
        let info = await task.value
        inFlight = nil

        guard let info else {
            // refresh 실패여도 만료는 확정한다 — "refresh 결과와 무관하게"가 정책이다.
            if let expiryCandidate {
                await finalizeLocalExpiry(of: expiryCandidate)
            }
            return nil
        }

        if let departure = info.departureTime, departure > Date() {
            // 서버 우선 — 미래 출발 시각이 오면 만료 후보·확정 기록 모두 해제하고 정상 경로.
            locallyExpiredSession = nil
        } else if let expiryCandidate {
            // 성공했지만 여전히 과거 세션(또는 출발 시각 없음) — 만료 확정.
            // 이 결과는 구독자에게 흘리지 않는다(죽은 세션으로 배너·버튼 복원 금지).
            await finalizeLocalExpiry(of: expiryCandidate)
            return info
        } else if let expired = locallyExpiredSession, expired.lastRouteId == info.lastRouteId {
            // 만료 확정 후 같은 과거 세션의 재수신 — 무시(2차 방어).
            Self.logger.info("만료 확정 세션 재수신 → 무시: route=\(info.lastRouteId, privacy: .public)")
            return info
        }

        Self.logger.info("알람 동기화 성공: route=\(info.lastRouteId, privacy: .public)")
        let previous = lastInfo
        lastInfo = info
        for continuation in subscribers.values {
            continuation.yield(info)
        }
        // Phase 11 피기백 — 이 시점에 알람 재스케줄은 이미 완료돼 있다
        // (RefreshAlarmUseCase.execute 반환 = 재스케줄 포함). 표출은 그 뒤에만 덧붙는다.
        await propagateChange(previous: previous, latest: info)
        return info
    }

    // MARK: - Phase 13 클라 자체 만료 (wake 시점 판정)

    /// sync 진입 선행 판정 — 보유 세션이 만료 유예(출발+60초, AlarmTiming 단일 기준)를
    /// 넘겼으면 만료 후보를 반환한다. 판정 자체는 Domain 순수 함수(시각 주입 테스트 대상).
    private func expireLocallyIfNeeded(now: Date) -> AlarmInfo? {
        guard let lastInfo,
              let departure = lastInfo.departureTime,
              AlarmTiming.isSessionExpired(departureTime: departure, now: now)
        else { return nil }
        return lastInfo
    }

    /// 만료 확정 = 로컬 sessionEnded 처리: 알람 레코드 정리 → LA 최종 종료 →
    /// changes yield(홈 정리는 기존 sessionEnded 소비 경로 재사용). 서버 계약 무관여.
    private func finalizeLocalExpiry(of session: AlarmInfo) async {
        Self.logger.info(
            "클라 자체 만료 확정(로컬 sessionEnded): route=\(session.lastRouteId, privacy: .public)"
        )
        locallyExpiredSession = session
        // replay-1이 죽은 세션을 재구독자에게 되살리지 않도록 비운다.
        lastInfo = nil
        await presentSessionEnded(previous: session, now: Date())
        yieldChange(.sessionEnded)
    }

    // MARK: - Phase 11·12 변경 표출 (판정 → LA/로컬 노티/인앱 채널)

    /// 판정 → 채널 분기. LA 호출은 전부 실패 무해(포트가 non-throwing) — 알람에 영향 없음.
    private func propagateChange(previous: AlarmInfo?, latest: AlarmInfo) async {
        let now = Date()
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
        let alarmTime = AlarmTiming.alarmFireDate(departureTime: departure)
        let badgeExpiry = now.addingTimeInterval(Self.changeBadgeDuration)

        guard alarmTime > now else {
            // 새 알람 시각이 이미 과거(출발은 미래) — 마지노선 침범. 원래 울렸어야 할 알람
            // 시점이 지나 있으므로 조용한 채널로는 늦다: 포그라운드 여부와 무관하게 즉시 최후통첩.
            let alert = (
                title: LastTrainChangeMessages.ultimatumTitle,
                body: LastTrainChangeMessages.ultimatumBody(latestDeparture: departure)
            )
            if await liveActivity.isDismissedByUser {
                // dismiss 폴백(Phase 12) — LA는 유저가 지웠다: alert를 실을 update는 no-op이고
                // push-to-start 재생성은 하지 않는다(어차피 세션도 없고, 지운 의사 존중이 정책).
                // 피기백 시점엔 앱이 깨어 있으므로 서버 무관여 로컬 노티로 같은 문구를 보낸다.
                await localNotification.post(title: alert.title, body: alert.body)
            } else {
                await liveActivity.update(state: LastTrainActivityState(
                    departureTime: departure,
                    alarmTime: alarmTime,
                    urgency: .imminent,
                    changeBadgeExpiry: badgeExpiry,
                    phase: .active
                ), alert: alert)
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
        if UIApplication.shared.applicationState == .active {
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
        if await liveActivity.isDismissedByUser {
            // dismiss 폴백(Phase 12) — LA alert 대신 같은 행동 중심 문구의 로컬 노티.
            // push-to-start 재생성 금지(정책) — 지워진 LA를 되살리지 않는다.
            await localNotification.post(title: alert.title, body: alert.body)
        } else {
            // 잠금화면 alert + "당겨짐" 배지(만료 now+10분).
            await liveActivity.update(state: state, alert: alert)
        }
    }

    /// 못 탐(advanced, actionable: false) 표출 — LA를 실패 상태(missed)로 전환한다.
    /// 알람은 손대지 않는다: 과거 fireDate 재스케줄은 RefreshAlarmUseCase가 이미 걸렀고,
    /// 이미 울렸거나 임박한 알람을 지우는 것은 인지 기회만 줄인다.
    private func presentMissed(latest: AlarmInfo, now: Date) async {
        // actionable=false 판정은 departureTime이 있을 때만 나온다(없으면 sessionEnded).
        guard let departure = latest.departureTime else { return }
        let state = LastTrainActivityState(
            departureTime: departure,
            alarmTime: AlarmTiming.alarmFireDate(departureTime: departure),
            urgency: .imminent,
            changeBadgeExpiry: nil,
            phase: .missed
        )
        // TODO(#9 임시 — 문구만): 대안 제시 데이터(심야버스·첫차 등) 확보 시 본문에 대안 안내를 싣는다.
        let alert = (
            title: LastTrainChangeMessages.missedTitle,
            body: LastTrainChangeMessages.missedBody(latestDeparture: departure)
        )
        if UIApplication.shared.applicationState == .active {
            // 포그라운드 — 상태 전환만 조용히. 사용자 주의는 인앱 채널이 맡는다(이중 알림 방지).
            await liveActivity.update(state: state, alert: nil)
        } else if await liveActivity.isDismissedByUser {
            // dismiss 폴백(Phase 12) — push-to-start 재생성 금지, 같은 문구의 로컬 노티로 대신한다.
            await localNotification.post(title: alert.title, body: alert.body)
        } else {
            await liveActivity.update(state: state, alert: alert)
        }
    }

    /// 운행 종료·경로 소멸(sessionEnded) 표출 — LA를 최종 상태(serviceEnded)로 내리고
    /// 로컬 알람을 취소한다. 서버 측 알람 취소는 부르지 않는다 — 경로 소멸은 서버 재계산
    /// 결과 그 자체라 이미 반영돼 있다.
    /// TODO: [미확정] 서버가 종료 후에도 세션을 남겨 두는 스펙으로 확정되면 취소 API 연동을 재검토한다.
    private func presentSessionEnded(previous: AlarmInfo?, now: Date) async {
        // 더는 울리면 안 되는 것이 정책의 핵심 — 표출(LA 종료)보다 알람 취소를 먼저 한다.
        await alarmScheduler.cancelAlarm()

        // sessionEnded 응답에는 departureTime이 없다 — 종료 시각 정보용으로 직전 스냅샷
        // (previous = 갱신 전 lastInfo)의 마지막 출발 시각을 쓰고, 그것도 없으면 now.
        let departure = previous?.departureTime ?? now
        // 유저가 이미 LA를 지웠으면 end는 no-op — 종료는 행동을 요구하지 않으므로
        // 로컬 노티 폴백도 없다(배너 정리는 changes 스트림을 받은 홈이 한다).
        await liveActivity.end(final: LastTrainActivityState(
            departureTime: departure,
            alarmTime: AlarmTiming.alarmFireDate(departureTime: departure),
            // 위젯은 serviceEnded phase 키로 그린다 — urgency는 종료 화면에선 의미 없는 방어값.
            urgency: .imminent,
            changeBadgeExpiry: nil,
            phase: .serviceEnded
        ))
    }

    /// 갱신된 AlarmInfo → LA 상태. departureTime이 없으면(세션 종료 등) 만들 수 없다.
    private func activityState(for info: AlarmInfo, now: Date) -> LastTrainActivityState? {
        guard let departure = info.departureTime else { return nil }
        let alarmTime = AlarmTiming.alarmFireDate(departureTime: departure)
        return LastTrainActivityState(
            departureTime: departure,
            alarmTime: alarmTime,
            urgency: LastTrainUrgency.forTimeRemaining(alarmTime.timeIntervalSince(now)),
            changeBadgeExpiry: nil,
            phase: .active
        )
    }

    private func yieldChange(_ verdict: AlarmChangeVerdict) {
        for continuation in changeSubscribers.values {
            continuation.yield(verdict)
        }
    }

    // MARK: - AlarmSyncEvents

    nonisolated func updates() -> AsyncStream<AlarmInfo> {
        AsyncStream { continuation in
            let id = UUID()
            Task { @MainActor in
                if let last = self.lastInfo {
                    continuation.yield(last)
                }
                self.subscribers[id] = continuation
            }
            continuation.onTermination = { _ in
                Task { @MainActor in
                    self.subscribers.removeValue(forKey: id)
                }
            }
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
