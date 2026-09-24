#if DEV
import Domain
import Foundation

// Phase 11 변경 시뮬레이터 (DEV 한정 — 자동 검수 규약의 전제).
//
// 막차 "변경"(앞당김/늦춤/운행종료) → 판정 → 알람 재스케줄 → LA alert/홈 배너 경로는
// 실서버가 임의로 재현해줄 수 없다. refresh 주입 가로채기만 남긴 슬림 데코레이터로,
// 과거 DevDemoFallbacks의 "실패 시 데모 데이터·에러 무시" 폴백은 전부 제거됐다 —
// 서버 실패는 이제 DEV에서도 그대로 표면화된다.

/// AlarmRepository 데코레이터 — 보류 중 주입이 있을 때만 refresh를 가로챈다.
/// register/cancel은 base에 그대로 위임한다(에러 은폐 없음).
struct DevChangeSimulatingAlarmRepository: AlarmRepository {
    let base: any AlarmRepository

    func register(lastRouteId: String) async throws {
        try await base.register(lastRouteId: lastRouteId)
        // 새 세션 시작 — 변경 시뮬레이터가 이 경로를 기준으로 변형한다.
        await DevChangeSimulator.shared.noteKnownSession(routeId: lastRouteId, departureTime: nil)
    }

    func cancel(lastRouteId: String) async throws {
        try await base.cancel(lastRouteId: lastRouteId)
    }

    func refresh() async throws -> AlarmRefreshOutcome {
        // 보류 중 변경 주입이 있으면 서버 대신 시뮬레이터가 응답한다(1회 소비).
        if let injected = await DevChangeSimulator.shared.consumeInjectedInfo() {
            print("⚠️ [DEV 변경 시뮬레이터] 변형 AlarmInfo 반환: departure=\(String(describing: injected.departureTime))")
            return .registered(injected)
        }
        let outcome = try await base.refresh()
        if case let .registered(info) = outcome {
            await DevChangeSimulator.shared.noteKnownSession(
                routeId: info.lastRouteId, departureTime: info.departureTime
            )
        }
        return outcome
    }
}

/// 막차 변경 피기백(판정 → 알람 재스케줄 → LA alert/홈 배너)을 검수할 유일한 주입 수단.
/// `DevChangeSimulatingAlarmRepository.refresh()`가 보류 중 주입을 소비해,
/// 마지막으로 알려진 출발 시각 기준으로 변형된 AlarmInfo를 반환한다.
@MainActor
final class DevChangeSimulator {
    static let shared = DevChangeSimulator()

    enum Injection {
        /// 출발 시각을 N초 앞당긴다 → advanced 판정 유도.
        case advance(TimeInterval)
        /// 출발 시각을 N초 늦춘다 → delayed 판정 유도.
        case delay(TimeInterval)
        /// 운행 종료 — departureTime 없는 응답으로 sessionEnded 판정 유도.
        case end
    }

    /// 알려진 세션의 UserDefaults 키 (Phase 14 검수) — 강제 종료·재실행 검수에서
    /// 기준 출발 시각을 잃으면 주입 diff·카드 복원 시각이 어긋나므로 DEV 한정 영속화한다.
    private static let knownRouteIdKey = "dev.sim.knownRouteId"
    private static let knownDepartureKey = "dev.sim.knownDeparture"

    private var pending: Injection?
    /// 마지막으로 알려진 세션 — 등록·refresh 성공·주입 적용 시 갱신된다.
    private var knownRouteId: String?
    private var knownDepartureTime: Date?

    private init() {
        knownRouteId = UserDefaults.standard.string(forKey: Self.knownRouteIdKey)
        let epoch = UserDefaults.standard.double(forKey: Self.knownDepartureKey)
        knownDepartureTime = epoch > 0 ? Date(timeIntervalSince1970: epoch) : nil
    }

    /// 주입 예약 — 다음 refresh() 1회가 소비한다.
    func inject(_ injection: Injection) {
        pending = injection
        print("⚠️ [DEV 변경 시뮬레이터] 주입 보류: \(injection)")
    }

    /// departureTime이 nil이면 routeId만 갱신한다(등록 경로는 출발 시각을 모른다).
    func noteKnownSession(routeId: String, departureTime: Date?) {
        knownRouteId = routeId
        UserDefaults.standard.set(routeId, forKey: Self.knownRouteIdKey)
        if let departureTime {
            knownDepartureTime = departureTime
            UserDefaults.standard.set(
                departureTime.timeIntervalSince1970, forKey: Self.knownDepartureKey
            )
        }
    }

    /// 알려진 세션의 출발 시각 — routeId가 일치할 때만 (상세 복원의 시각 정합용).
    func knownSessionDeparture(routeId: String) -> Date? {
        knownRouteId == routeId ? knownDepartureTime : nil
    }

    /// 보류 중 주입을 소비해 변형된 AlarmInfo를 만든다. 주입이 없으면 nil.
    /// 적용 결과를 기준 시각으로 다시 캐시하므로 주입을 연달아 합성할 수 있다
    /// (예: "10분 늦춤" 뒤 "5분 앞당김" → actionable alert 경로 검수).
    func consumeInjectedInfo(now: Date = Date()) -> AlarmInfo? {
        guard let injection = pending else { return nil }
        pending = nil
        let routeId = knownRouteId ?? "dev-demo-route"
        // 기준 출발 시각: 캐시가 없으면 데모 경로 기본값(now+3분)과 같은 가정.
        let base = knownDepartureTime ?? now.addingTimeInterval(3 * 60)

        let departure: Date?
        switch injection {
        case .advance(let seconds): departure = base.addingTimeInterval(-seconds)
        case .delay(let seconds): departure = base.addingTimeInterval(seconds)
        case .end: departure = nil
        }
        knownDepartureTime = departure
        if let departure {
            UserDefaults.standard.set(
                departure.timeIntervalSince1970, forKey: Self.knownDepartureKey
            )
        }
        return AlarmInfo(
            lastRouteId: routeId,
            departureTime: departure,
            updatedAt: now,
            isReal: true
        )
    }
}
#endif
