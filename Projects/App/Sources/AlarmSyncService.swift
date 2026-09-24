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
/// **이 타입이 하는 일은 트리거를 모으는 것뿐이다.** 변경 표출은
/// `AlarmChangePresenter`, 세션 소유는 `AlarmSessionStore`, 만료·서버우선 판정은
/// `AlarmSessionReconciler`(순수 함수)가 맡는다.
///
/// 이전에는 한 타입이 프로토콜 3개를 동시 구현하며 575줄이었다 — 셋 다 "같은 세션"을
/// 필요로 해서였는데, 세션을 Store가 소유하게 되자 서로를 알 필요가 없어졌다.
///
/// 세션 스트림(`AlarmSyncEvents`)도 이 타입이 제공하지 않는다 — 소유자인 Store가
/// 직접 구현한다. 중계하면 끝나지 않는 스트림을 구독하는 Task가 해제되지 않아
/// 테스트 프로세스가 종료되지 못한다(실측).
// Sendable 프로토콜(AlarmSyncEvents 등) 채택이 기본 MainActor 격리를 nonisolated로
// 추론시키므로 명시한다 — 상태(subscribers 등)는 전부 메인 액터에서만 만진다.
@MainActor
final class AlarmSyncService: AlarmSyncRequesting {
    private let refreshAlarmUseCase: any RefreshAlarmUseCase
    /// 변경 표출 전담 — 판정·LA·노티·인앱 채널은 전부 저쪽 책임이다.
    private let presenter: AlarmChangePresenter
    /// 세션의 단일 소유자 — 읽기·쓰기·구독이 전부 여기를 통한다.
    /// 이 서비스는 더 이상 세션 상태를 필드로 들지 않는다.
    private let sessionStore: AlarmSessionStore
    /// 죽은 세션 LA 재시작 경로(Phase 14) — dismiss·확인 기록 판정은 어댑터가 한다.
    private let sessionRestorer: any LastTrainSessionRestoring
    /// 만료·판정·스탬프의 시각 주입(Phase 16) — 실 Date() 직접 호출 제거(기존 관례).
    private let now: @Sendable () -> Date
    /// 시계 틱 간격 — 테스트가 줄여 주입한다(기본 1분).
    private let tickInterval: Duration
    private static let logger = Logger(subsystem: "com.atcha.iOS.v2", category: "AlarmSync")

    /// 변경 판정의 "이전 값" — 세션 자체가 아니라 **직전 sync의 서버 값**이라 여기 둔다.
    /// 세션은 Store가 소유하고, 이건 diff 한 번에만 쓰이는 지역 기억이다.
    private var previousServerInfo: AlarmInfo?
    /// 진행 중 동기화 — 트리거가 겹치면(예: 앱 시작 직후 포그라운드 노티) 합류한다.
    private var inFlight: Task<AlarmRefreshOutcome?, Never>?
    private var foregroundObserver: (any NSObjectProtocol)?

    // 앱 수명 객체(조합 루트 소유) — 해제 경로가 없어 관찰 해지/태스크 취소 정리가 없다.
    init(
        refreshAlarmUseCase: any RefreshAlarmUseCase,
        presenter: AlarmChangePresenter,
        sessionStore: AlarmSessionStore,
        sessionRestorer: any LastTrainSessionRestoring,
        now: @escaping @Sendable () -> Date = { Date() },
        tickInterval: Duration = .seconds(60)
    ) {
        self.refreshAlarmUseCase = refreshAlarmUseCase
        self.presenter = presenter
        self.sessionStore = sessionStore
        self.sessionRestorer = sessionRestorer
        self.now = now
        self.tickInterval = tickInterval
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
        // 시간 경과 만료 감지 — 판정은 Store(=Reconciler), 표출은 여기가 맡는다.
        // 이전에는 홈 ViewModel의 배너 타이머가 판정까지 했다.
        sessionStore.startTicking(interval: tickInterval) { [presenter] expired in
            await presenter.presentLocalExpiry(of: expired)
        }
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
        sessionStore.stopTicking()
        previousServerInfo = nil
        presenter.reset()
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
            return await inFlight.value?.info
        }
        Self.logger.info("알람 동기화 시작")
        // 재실행 브리지 복원 — 세션을 디스크에서 되살린다. Store가 1회만 수행한다.
        await sessionStore.bootstrap()
        let current = sessionStore.current
        // diff의 "이전 값"은 이번 갱신 **전**의 서버 값이다.
        previousServerInfo = current?.server

        // nil = 조회 실패(세션 유지). `.notRegistered` = 서버가 없다고 확정(정리).
        // 이 구분이 없던 시절엔 서버의 "등록된 알람 없음"(404 URT_001)이 실패로 흘러,
        // 세션이 사라져도 앱이 계속 붙들고 매 실행마다 에러 로그가 남았다.
        let task = Task { [refreshAlarmUseCase, current] () -> AlarmRefreshOutcome? in
            do {
                return try await refreshAlarmUseCase.execute(current: current)
            } catch {
                Self.logger.info("알람 동기화 실패(상태 유지): \(error)")
                return nil
            }
        }
        inFlight = task
        let outcome = await task.value
        inFlight = nil
        let info = outcome?.info

        // 만료·서버 우선·톰스톤 메아리 판정이 전부 여기 한 번에 일어난다.
        // 이전에는 이 판단이 선행 만료 후보 → refresh → 3분기 서버 우선 → 톰스톤 기록으로
        // 흩어져 있었다(그래서 "1차 방어 / 2차 방어" 주석이 붙었다).
        let reconciled = AlarmSessionReconciler.reconcile(
            current: current, server: outcome, now: now()
        )
        await sessionStore.apply(reconciled)

        switch reconciled {
        case let .refreshed(session):
            Self.logger.info(
                "알람 동기화 성공: route=\(session.server.lastRouteId, privacy: .public)"
            )
            // 죽은 세션 재시작 — 세션은 살아 있는데 활성 LA가 없고 dismiss·확인 기록도
            // 없으면 로컬 재시작(판정은 어댑터). 8시간 한도·시작 실패 세션 커버.
            await sessionRestorer.restartIfNeeded(session: session, now: now())
            // 알람 재스케줄은 RefreshAlarmUseCase 안에서 이미 끝났다(반환 = 재스케줄 완료) —
            // 표출은 그 뒤에만 덧붙으므로 LA·노티 실패가 알람을 막을 구조가 없다.
            await presenter.propagateChange(previous: previousServerInfo, latest: session.server)
            return session.server

        case let .expired(session):
            // 로컬 sessionEnded 처리. 톰스톤 저장은 Store가 이미 했다.
            await presenter.presentLocalExpiry(of: session)
            return info

        case .ended:
            // 서버가 세션 종료를 확정 — 표출은 propagateChange의 sessionEnded 분기가 맡는다.
            if let info {
                await presenter.propagateChange(previous: previousServerInfo, latest: info)
            }
            return info

        case .ignoredStaleEcho:
            Self.logger.info("만료 확정 세션 재수신 → 무시")
            return info
        }
    }
    // MARK: - Phase 11·12 변경 표출 (판정 → LA/로컬 노티/인앱 채널)
}
