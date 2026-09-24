import Domain
import Foundation
import UIKit
import os

/// 서버발 알람 시각 갱신의 단일 진입점. 앱 시작·포그라운드 복귀·사일런트 푸시·홈
/// pull-to-refresh 4경로가 전부 여기의 `RefreshAlarmUseCase` 호출 한 곳으로 모인다
/// (`inFlight` 합류가 있어 트리거가 겹쳐도 refresh는 1회).
///
/// **세션 상태는 이 타입이 들지 않는다** — `AlarmSessionStore`가 소유하고, 여기는
/// 트리거를 모으고 판정 결과를 표출 채널로 흘리는 일만 한다. 만료·서버 우선·톰스톤
/// 메아리 판정은 `AlarmSessionReconciler`(순수 함수)가 한 번에 내린다.
///
/// 변경 표출: 갱신 성공 뒤 전/후 `AlarmInfo`를 판정(`EvaluateAlarmChangeUseCase`)해
/// ① LA 채널(당겨짐 alert / 늦춰짐 조용한 갱신)과 ② 인앱 채널(`AlarmChangeEvents` →
/// 홈 배너 강조·토스트)에 덧붙인다. 알람 재스케줄은 `RefreshAlarmUseCase.execute()`
/// 안에서 이미 끝난 뒤라(반환 = 재스케줄 완료) 표출 실패가 알람을 막을 구조가 없다.
///
/// 폴백·종료: ③ LA alert가 도달 불가(dismissed ∨ 활성 activity 없음 ∨ LA 비활성 —
/// 어댑터의 `isAlertReachable` 단일 판정)면 백그라운드 alert를 로컬 노티(같은 문구,
/// time-sensitive)로 갈아탄다. push-to-start 재생성은 하지 않는다(지운 의사 존중).
/// ④ advanced(actionable: false)는 LA를 missed로, sessionEnded는 serviceEnded 최종
/// 상태로 내리고 로컬 알람을 취소한다. 배너 정리는 changes 스트림을 받은 홈의 몫.
///
/// 세션 스트림(`AlarmSyncEvents`)은 이 타입이 제공하지 않는다 — 소유자인
/// `AlarmSessionStore`가 직접 구현한다. 중계하면 끝나지 않는 스트림을 구독하는 Task가
/// 해제되지 않아 테스트 프로세스가 종료되지 못한다(실측).
///
/// 표출 채널 분기용 `isAppActive`와 `now`는 주입이다 — App 테스트 타겟의 회귀 방어 대상.
// Sendable 프로토콜(AlarmSyncEvents 등) 채택이 기본 MainActor 격리를 nonisolated로
// 추론시키므로 명시한다 — 상태(subscribers 등)는 전부 메인 액터에서만 만진다.
@MainActor
final class AlarmSyncService: AlarmChangeEvents, AlarmSyncRequesting {
    private let refreshAlarmUseCase: any RefreshAlarmUseCase
    private let evaluateChangeUseCase: any EvaluateAlarmChangeUseCase
    /// LA 표출 경로 — non-throwing 계약(어댑터가 실패 흡수)이라 이 훅의 어떤 실패도 무해하다.
    private let liveActivity: any LastTrainChangeAlerting
    /// dismiss 폴백 채널(Phase 12) — 유저가 LA를 지운 뒤의 변경 alert를 로컬 노티로 대신한다.
    /// 발송도 non-throwing(권한 없으면 조용히 no-op) — 여기서 권한을 요청하는 일은 절대 없다.
    private let localNotification: any LocalNotificationPort
    /// sessionEnded 시 로컬 알람 취소용(Phase 12) — 등록/갱신 UseCase와 같은 스케줄러를 공유한다.
    private let alarmScheduler: any AlarmScheduler
    /// 세션의 단일 소유자 — 읽기·쓰기·구독이 전부 여기를 통한다.
    /// 이 서비스는 더 이상 세션 상태를 필드로 들지 않는다.
    private let sessionStore: AlarmSessionStore
    /// 죽은 세션 LA 재시작 경로(Phase 14) — dismiss·확인 기록 판정은 어댑터가 한다.
    private let sessionRestorer: any LastTrainSessionRestoring
    /// 표출 채널 분기용 앱 활성 판정(Phase 16) — UIApplication 직접 참조를 걷어내
    /// 테스트가 상태를 주입한다. 분기 의미(포그라운드 = 인앱 채널 단독)는 불변.
    private let isAppActive: @MainActor () -> Bool
    /// 만료·판정·스탬프의 시각 주입(Phase 16) — 실 Date() 직접 호출 제거(기존 관례).
    private let now: @Sendable () -> Date
    private static let logger = Logger(subsystem: "com.atcha.iOS.v2", category: "AlarmSync")

    /// "⚠ 당겨짐" 배지 유지 시간 — 정책: 표출 시점 + 10분.
    private static let changeBadgeDuration: TimeInterval = 600

    /// 변경 판정 구독자 — 세션 스트림과 달리 **replay 없음**(과거 변경이 재구독 시 재발화 금지).
    /// "상태는 replay-1, 사건은 replay 없음"의 사건 쪽이다.
    private var changeSubscribers: [UUID: AsyncStream<AlarmChangeVerdict>.Continuation] = [:]
    /// 변경 판정의 "이전 값" — 세션 자체가 아니라 **직전 sync의 서버 값**이라 여기 둔다.
    /// 세션은 Store가 소유하고, 이건 diff 한 번에만 쓰이는 지역 기억이다.
    private var previousServerInfo: AlarmInfo?
    /// "⚠ 당겨짐" 배지의 현재 만료 시각 — 조용한 갱신(unchanged/delayed)이 배지를 10분
    /// 정책보다 일찍 지우지 않도록 보존한다(Phase 14 정합).
    private var changeBadgeExpiry: Date?
    /// 진행 중 동기화 — 트리거가 겹치면(예: 앱 시작 직후 포그라운드 노티) 합류한다.
    private var inFlight: Task<AlarmInfo?, Never>?
    private var foregroundObserver: (any NSObjectProtocol)?

    // 앱 수명 객체(조합 루트 소유) — 해제 경로가 없어 관찰 해지/태스크 취소 정리가 없다.
    init(
        refreshAlarmUseCase: any RefreshAlarmUseCase,
        evaluateChangeUseCase: any EvaluateAlarmChangeUseCase,
        liveActivity: any LastTrainChangeAlerting,
        localNotification: any LocalNotificationPort,
        alarmScheduler: any AlarmScheduler,
        sessionStore: AlarmSessionStore,
        sessionRestorer: any LastTrainSessionRestoring,
        isAppActive: @escaping @MainActor () -> Bool = {
            UIApplication.shared.applicationState == .active
        },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.refreshAlarmUseCase = refreshAlarmUseCase
        self.evaluateChangeUseCase = evaluateChangeUseCase
        self.liveActivity = liveActivity
        self.localNotification = localNotification
        self.alarmScheduler = alarmScheduler
        self.sessionStore = sessionStore
        self.sessionRestorer = sessionRestorer
        self.isAppActive = isAppActive
        self.now = now
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

    // MARK: - 계정 세션 종료 (로그아웃·탈퇴·만료)

    /// 현재 보유 세션 — 로그아웃 시 서버 취소 대상 routeId의 출처.
    var currentSession: AlarmInfo? { sessionStore.current?.server }

    /// 계정이 바뀌면 이전 계정의 세션 기억이 새 계정의 diff·만료 판정을 오염시킨다 —
    /// 메모리 상태를 전부 비우고, 다음 로그인의 첫 sync가 (이미 비워진) 스냅샷부터 다시 시딩한다.
    func resetForSignOut() async {
        inFlight?.cancel()
        inFlight = nil
        previousServerInfo = nil
        changeBadgeExpiry = nil
        // 세션 기록 자체는 Store가 지운다 — 이전 계정의 세션이 새 계정의 diff·만료
        // 판정을 오염시키면 안 된다.
        await sessionStore.reset()
    }

    // MARK: - AlarmSyncRequesting (Phase 16 — 홈 pull-to-refresh)

    /// 수동 갱신 트리거(4번째) — 기존 sync()에 그대로 합류한다. 실패는 던지지 않고
    /// 스트림에도 흐르지 않는다(무음 정책) — 스탬프가 낡은 시각을 유지하는 것이 표면이다.
    /// 테스트 진입점이기도 하다(NotificationCenter 없이 전 분기 도달).
    nonisolated func syncNow() async {
        _ = await sync()
    }

    /// 3경로 공용 동기화. 실패는 스트림에 흘리지 않는다 — 구독자는 상태를 유지하고,
    /// 다음 트리거(포그라운드·푸시)가 자연 재시도가 된다.
    @discardableResult
    private func sync() async -> AlarmInfo? {
        if let inFlight {
            return await inFlight.value
        }
        Self.logger.info("알람 동기화 시작")
        // 재실행 브리지 복원 — 세션을 디스크에서 되살린다. Store가 1회만 수행한다.
        await sessionStore.bootstrap()
        let current = sessionStore.current
        // diff의 "이전 값"은 이번 갱신 **전**의 서버 값이다.
        previousServerInfo = current?.server

        let task = Task { [refreshAlarmUseCase, current] () -> AlarmInfo? in
            do {
                return try await refreshAlarmUseCase.execute(current: current)
            } catch {
                Self.logger.info("알람 동기화 실패(상태 유지): \(error)")
                return nil
            }
        }
        inFlight = task
        let info = await task.value
        inFlight = nil

        // 만료·서버 우선·톰스톤 메아리 판정이 전부 여기 한 번에 일어난다.
        // 이전에는 이 판단이 선행 만료 후보 → refresh → 3분기 서버 우선 → 톰스톤 기록으로
        // 흩어져 있었다(그래서 "1차 방어 / 2차 방어" 주석이 붙었다).
        let outcome = AlarmSessionReconciler.reconcile(
            current: current, server: info, now: now()
        )
        await sessionStore.apply(outcome)

        switch outcome {
        case let .refreshed(session):
            Self.logger.info(
                "알람 동기화 성공: route=\(session.server.lastRouteId, privacy: .public)"
            )
            // 죽은 세션 재시작 — 세션은 살아 있는데 활성 LA가 없고 dismiss·확인 기록도
            // 없으면 로컬 재시작(판정은 어댑터). 8시간 한도·시작 실패 세션 커버.
            await sessionRestorer.restartIfNeeded(session: session, now: now())
            // 알람 재스케줄은 RefreshAlarmUseCase 안에서 이미 끝났다(반환 = 재스케줄 완료) —
            // 표출은 그 뒤에만 덧붙으므로 LA·노티 실패가 알람을 막을 구조가 없다.
            await propagateChange(previous: previousServerInfo, latest: session.server)
            return session.server

        case let .expired(session):
            // 로컬 sessionEnded 처리. 톰스톤 저장은 Store가 이미 했다.
            await presentSessionEnded(previous: session.server, now: now())
            yieldChange(.sessionEnded)
            return info

        case .ended:
            // 서버가 세션 종료를 확정 — 표출은 propagateChange의 sessionEnded 분기가 맡는다.
            if let info {
                await propagateChange(previous: previousServerInfo, latest: info)
            }
            return info

        case .ignoredStaleEcho:
            Self.logger.info("만료 확정 세션 재수신 → 무시")
            return info
        }
    }

    /// 세션이 아는 도보 초로 알람 시각을 계산한다. **도보 초를 읽는 유일한 경로**가
    /// `AlarmSession.fireDate`이므로, 세션이 없을 때만 버퍼 폴백을 쓴다.
    private func alarmFireDate(departureTime: Date) -> Date {
        AlarmTiming.alarmFireDate(
            departureTime: departureTime,
            firstWalkSeconds: sessionStore.current?.local.firstWalkSeconds
        )
    }

    // MARK: - Phase 11·12 변경 표출 (판정 → LA/로컬 노티/인앱 채널)

    /// 판정 → 채널 분기. LA 호출은 전부 실패 무해(포트가 non-throwing) — 알람에 영향 없음.
    private func propagateChange(previous: AlarmInfo?, latest: AlarmInfo) async {
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
