@testable import Domain
import Foundation
import Testing

/// 이전에는 만료 판정이 세 주체(홈 VM 가드 / 동기화 서비스 / 스냅샷 톰스톤)에 흩어져
/// 있어서, 이 조합들을 검증하려면 네트워크·스토어·LA·노티 스텁을 다 조립해야 했다.
/// 순수 함수가 되면 **스텁 0개**로 같은 판정을 표로 확인할 수 있다.
struct AlarmSessionReconcilerTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func info(
        route: String = "R1",
        departureOffset: TimeInterval?,
        isReal: Bool = true
    ) -> AlarmInfo {
        AlarmInfo(
            lastRouteId: route,
            departureTime: departureOffset.map { now.addingTimeInterval($0) },
            updatedAt: now,
            isReal: isReal
        )
    }

    private func session(
        route: String = "R1",
        departureOffset: TimeInterval?,
        walkSeconds: Int? = 300,
        lifecycle: AlarmSession.Lifecycle = .active,
        syncedAt: Date? = nil
    ) -> AlarmSession {
        AlarmSession(
            server: info(route: route, departureOffset: departureOffset),
            local: .init(
                firstWalkSeconds: walkSeconds,
                routeDisplayName: "6411번 버스",
                transportMode: .bus
            ),
            lifecycle: lifecycle,
            syncedAt: syncedAt
        )
    }

    // MARK: - 발견 / 정상 갱신

    @Test
    func noCurrent_futureDeparture_refreshes() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: nil,
            server: info(departureOffset: 600),
            now: now
        )

        guard case let .refreshed(session) = outcome else {
            Issue.record("refreshed 기대, 실제 \(outcome)"); return
        }
        #expect(session.server.lastRouteId == "R1")
        // 로컬 사실을 모르는 상태로 시작한다 — 다음 등록이 채운다.
        #expect(session.local.firstWalkSeconds == nil)
        #expect(session.syncedAt == now)
    }

    /// 재실행 직후 발견한 세션이 이미 지난 막차면 곧장 톰스톤이어야 한다 —
    /// 되살아나 배너를 그리면 안 된다.
    @Test
    func noCurrent_pastDeparture_expiresImmediately() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: nil,
            server: info(departureOffset: -120),
            now: now
        )

        guard case let .expired(session) = outcome else {
            Issue.record("expired 기대, 실제 \(outcome)"); return
        }
        #expect(session.lifecycle == .ended)
    }

    @Test
    func noCurrentNoServer_isEnded() {
        #expect(
            AlarmSessionReconciler.reconcile(current: nil, server: nil, now: now) == .ended
        )
    }

    // MARK: - 서버 우선

    /// 로컬은 만료라고 보지만 서버가 미래 출발을 주면 **서버가 이긴다**.
    @Test
    func pastDeparture_serverGivesFuture_refreshesNotExpires() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(departureOffset: -120),
            server: info(departureOffset: 900),
            now: now
        )

        guard case let .refreshed(session) = outcome else {
            Issue.record("refreshed 기대, 실제 \(outcome)"); return
        }
        #expect(session.lifecycle == .active)
    }

    @Test
    func pastDeparture_serverConfirmsSamePast_expires() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(departureOffset: -120),
            server: info(departureOffset: -120),
            now: now
        )

        guard case .expired = outcome else {
            Issue.record("expired 기대, 실제 \(outcome)"); return
        }
    }

    /// 톰스톤이어도 같은 경로가 미래 시각을 들고 오면 되살린다(서버 우선).
    @Test
    func endedSession_serverGivesFuture_revives() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(departureOffset: -600, lifecycle: .ended),
            server: info(departureOffset: 900),
            now: now
        )

        guard case let .refreshed(session) = outcome else {
            Issue.record("refreshed 기대, 실제 \(outcome)"); return
        }
        #expect(session.lifecycle == .active)
    }

    /// 톰스톤 + 같은 경로 + 과거 시각 = 메아리. 지운 세션이 되살아나면 안 된다.
    @Test
    func endedSession_serverEchoesSamePast_isIgnored() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(departureOffset: -600, lifecycle: .ended),
            server: info(departureOffset: -600),
            now: now
        )

        #expect(outcome == .ignoredStaleEcho)
    }

    /// 톰스톤이어도 **다른 경로**는 새 세션이므로 채택한다.
    @Test
    func endedSession_differentRoute_acceptsAsNewSession() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(route: "R1", departureOffset: -600, lifecycle: .ended),
            server: info(route: "R2", departureOffset: 900),
            now: now
        )

        guard case let .refreshed(session) = outcome else {
            Issue.record("refreshed 기대, 실제 \(outcome)"); return
        }
        #expect(session.server.lastRouteId == "R2")
        #expect(session.lifecycle == .active)
    }

    // MARK: - 로컬 사실 보존 규칙

    /// 같은 경로면 도보 초·표시명을 보존한다 — 서버가 주지 않는 값이라 잃으면 복구 불가다.
    @Test
    func sameRoute_preservesLocalFacts() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(route: "R1", departureOffset: 600, walkSeconds: 300),
            server: info(route: "R1", departureOffset: 900),
            now: now
        )

        guard case let .refreshed(session) = outcome else {
            Issue.record("refreshed 기대, 실제 \(outcome)"); return
        }
        #expect(session.local.firstWalkSeconds == 300)
        #expect(session.local.routeDisplayName == "6411번 버스")
    }

    /// 다른 경로면 **버려야** 한다. 들고 가면 그 경로의 것이 아닌 도보 초로
    /// 알람이 틀린 시각에 울린다.
    @Test
    func differentRoute_dropsLocalFacts() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(route: "R1", departureOffset: 600, walkSeconds: 300),
            server: info(route: "R2", departureOffset: 900),
            now: now
        )

        guard case let .refreshed(session) = outcome else {
            Issue.record("refreshed 기대, 실제 \(outcome)"); return
        }
        #expect(session.local.firstWalkSeconds == nil)
        #expect(session.local.routeDisplayName.isEmpty)
    }

    // MARK: - 수명 보존

    @Test
    func acknowledgedSession_refresh_keepsLifecycle() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(departureOffset: 600, lifecycle: .acknowledged),
            server: info(departureOffset: 900),
            now: now
        )

        guard case let .refreshed(session) = outcome else {
            Issue.record("refreshed 기대, 실제 \(outcome)"); return
        }
        #expect(session.lifecycle == .acknowledged)
    }

    /// 확인된 세션도 출발 시각이 지나면 톰스톤이 된다(acknowledged → ended 전이).
    @Test
    func acknowledgedSession_pastDeparture_expires() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(departureOffset: -120, lifecycle: .acknowledged),
            server: nil,
            now: now
        )

        guard case let .expired(session) = outcome else {
            Issue.record("expired 기대, 실제 \(outcome)"); return
        }
        #expect(session.lifecycle == .ended)
    }

    // MARK: - 서버 응답 없음 (오프라인·실패)

    /// 네트워크 실패가 "세션 소멸"이 되면 안 된다 — 미래 세션은 그대로 유지한다.
    @Test
    func serverUnavailable_futureSession_keptIntact() {
        let existing = session(departureOffset: 600, syncedAt: now.addingTimeInterval(-300))
        let outcome = AlarmSessionReconciler.reconcile(
            current: existing,
            server: nil,
            now: now
        )

        guard case let .refreshed(session) = outcome else {
            Issue.record("refreshed 기대, 실제 \(outcome)"); return
        }
        // 확인 시각을 갱신하지 않는다 — 서버에 닿지 못했으므로 낡은 시각이 정직하다.
        #expect(session.syncedAt == now.addingTimeInterval(-300))
    }

    @Test
    func serverUnavailable_endedSession_isIgnored() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(departureOffset: -600, lifecycle: .ended),
            server: nil,
            now: now
        )

        #expect(outcome == .ignoredStaleEcho)
    }

    // MARK: - 서버가 세션 없음을 알림

    @Test
    func serverDropsDepartureTime_isEnded() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(departureOffset: 600),
            server: info(departureOffset: nil),
            now: now
        )

        #expect(outcome == .ended)
    }

    // MARK: - 경계

    /// 만료 경계는 출발 + 유예(60초)다. 정확히 그 시점은 만료로 본다.
    @Test
    func expiryBoundary_exactlyAtGrace_expires() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(departureOffset: -AlarmTiming.expiryGraceSeconds),
            server: nil,
            now: now
        )

        guard case .expired = outcome else {
            Issue.record("expired 기대, 실제 \(outcome)"); return
        }
    }

    @Test
    func expiryBoundary_oneSecondBeforeGrace_survives() {
        let outcome = AlarmSessionReconciler.reconcile(
            current: session(departureOffset: -(AlarmTiming.expiryGraceSeconds - 1)),
            server: nil,
            now: now
        )

        guard case .refreshed = outcome else {
            Issue.record("refreshed 기대, 실제 \(outcome)"); return
        }
    }

    // MARK: - fireDate (도보 초를 읽는 유일한 지점)

    @Test
    func fireDate_subtractsWalkAndBuffer() {
        let session = session(departureOffset: 1800, walkSeconds: 300)

        #expect(
            session.fireDate == now.addingTimeInterval(1800 - 300 - AlarmTiming.bufferSeconds)
        )
    }

    /// 도보 초를 모르면 버퍼만 적용된다 — 알람이 도보 시간만큼 늦게 울리므로,
    /// 등록 경로가 이 값을 반드시 채워야 한다는 근거다.
    @Test
    func fireDate_withoutWalkSeconds_appliesBufferOnly() {
        let session = session(departureOffset: 1800, walkSeconds: nil)

        #expect(session.fireDate == now.addingTimeInterval(1800 - AlarmTiming.bufferSeconds))
    }

    @Test
    func fireDate_withoutDeparture_isNil() {
        let session = AlarmSession(
            server: info(departureOffset: nil),
            local: .empty
        )

        #expect(session.fireDate == nil)
    }

    // MARK: - LA 재시작 게이트

    @Test
    func allowsActivityRestart_onlyWhenActive() {
        #expect(session(departureOffset: 600, lifecycle: .active).allowsActivityRestart)
        #expect(!session(departureOffset: 600, lifecycle: .acknowledged).allowsActivityRestart)
        #expect(!session(departureOffset: 600, lifecycle: .ended).allowsActivityRestart)
    }
}
