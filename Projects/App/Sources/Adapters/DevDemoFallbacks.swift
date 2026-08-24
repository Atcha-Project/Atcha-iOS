#if DEV
import Domain
import Foundation

// DEV 검수용 임시 우회 (Phase 7 사람 검수 — 사용자 지시로 추가).
//
// 실서버가 미확정 입력 #1(실 base URL)·#2(익명 인증) 상태라 접속 불가인 동안에도
// 전체 플로우(검색 → 경로 선택 → 알람 등록 → 발화 → 해제)를 시연할 수 있게,
// 서버 호출이 "실패했을 때만" 데모 데이터로 대체하거나 실패를 무시한다.
// 서버가 살아나면 실데이터가 그대로 우선한다. Stage/Release에는 컴파일되지 않는다.
// 실서버 스펙 확정 시 이 파일과 AppDIContainer의 #if DEV 주입만 제거하면 된다.

struct DevDemoFallbackPlaceRepository: PlaceRepository {
    let base: any PlaceRepository

    func searchPlaces(keyword: String, near coordinate: Coordinate?) async throws -> [Place] {
        do { return try await base.searchPlaces(keyword: keyword, near: coordinate) }
        catch {
            print("⚠️ [DEV 우회] 장소 검색 실패 → 데모 장소 반환: \(error)")
            return [
                Place(
                    name: "\(keyword) (데모)",
                    address: "서울 강남구 강남대로 396",
                    coordinate: Coordinate(latitude: 37.4979, longitude: 127.0276)
                ),
                Place(
                    name: "구로디지털단지역 (데모)",
                    address: "서울 구로구 도림천로 486",
                    coordinate: Coordinate(latitude: 37.4853, longitude: 126.9015)
                ),
            ]
        }
    }

    func reverseGeocode(_ coordinate: Coordinate) async throws -> Place {
        do { return try await base.reverseGeocode(coordinate) }
        catch {
            print("⚠️ [DEV 우회] 역지오코딩 실패 → 데모 라벨 반환: \(error)")
            return Place(name: "현재 위치 (데모)", address: "", coordinate: coordinate)
        }
    }
}

struct DevDemoFallbackLastRouteRepository: LastRouteRepository {
    let base: any LastRouteRepository

    func searchLastRoutes(start: Coordinate, end: Coordinate) async throws -> [LastRoute] {
        do { return try await base.searchLastRoutes(start: start, end: end) }
        catch {
            print("⚠️ [DEV 우회] 막차 검색 실패 → 데모 경로 반환: \(error)")
            let route = Self.demoRoute(start: start, end: end)
            // 변경 시뮬레이터의 기준 출발 시각 — 데모 흐름에선 검색 직후 이 경로가 등록된다.
            await DevChangeSimulator.shared.noteKnownSession(
                routeId: route.id, departureTime: route.departureTime
            )
            return [route]
        }
    }

    func lastRoute(id: String) async throws -> LastRoute {
        do { return try await base.lastRoute(id: id) }
        catch {
            print("⚠️ [DEV 우회] 경로 상세 실패 → 데모 경로 반환: \(error)")
            // 카드 복원(Phase 14) 검수 정합: 알려진 세션(재실행 후에도 영속)의 출발 시각을
            // 재사용해야 배너·LA와 카드의 시각이 어긋나지 않는다. 모르면 새 데모 시각.
            let knownDeparture = await DevChangeSimulator.shared.knownSessionDeparture(routeId: id)
            let route = Self.demoRoute(
                start: Coordinate(latitude: 37.4979, longitude: 127.0276),
                end: Coordinate(latitude: 37.4853, longitude: 126.9015),
                departure: knownDeparture
            )
            await DevChangeSimulator.shared.noteKnownSession(
                routeId: route.id, departureTime: route.departureTime
            )
            return route
        }
    }

    /// 출발 시각은 8분 뒤 — 알람이 도보(첫 walk leg 120초)+버퍼(180초) 반영으로 +3분
    /// 시점에 걸린다(Phase 14 검수 ③: 배너·LA·발화가 전부 "출발 − 도보 − 3분" 기준).
    /// 더 이르면 등록 탭 시점에 이미 과거가 되어 tooLate 가드·AlarmKit 거부에 걸린다.
    private static func demoRoute(
        start: Coordinate, end: Coordinate, departure: Date? = nil
    ) -> LastRoute {
        let departure = departure ?? Date().addingTimeInterval(8 * 60)
        return LastRoute(
            id: "dev-demo-route",
            departureTime: departure,
            totalTime: 2940,
            totalWalkTime: 480,
            transferCount: 1,
            totalDistance: 14200,
            totalWalkDistance: 700,
            legs: [
                TransportLeg(
                    mode: .walk,
                    sectionTime: 120,
                    distance: 150,
                    departureTime: nil,
                    routeName: nil,
                    lineType: nil,
                    start: nil,
                    end: RoutePoint(name: "강남역", coordinate: start),
                    subwayFinalStation: nil,
                    subwayDirection: nil,
                    isExpressSubway: false,
                    isLastSubway: false
                ),
                TransportLeg(
                    mode: .subway,
                    sectionTime: 1500,
                    distance: 9000,
                    departureTime: departure,
                    routeName: "2호선",
                    lineType: "2",
                    start: RoutePoint(name: "강남역", coordinate: start),
                    end: RoutePoint(name: "당산역", coordinate: Coordinate(latitude: 37.5343, longitude: 126.9024)),
                    subwayFinalStation: "홍대입구행",
                    subwayDirection: "외선",
                    isExpressSubway: false,
                    isLastSubway: true
                ),
                TransportLeg(
                    mode: .bus,
                    sectionTime: 960,
                    distance: 4500,
                    departureTime: nil,
                    routeName: "간선:6411",
                    lineType: "11",
                    start: RoutePoint(name: "당산역", coordinate: Coordinate(latitude: 37.5343, longitude: 126.9024)),
                    end: RoutePoint(name: "구로디지털단지", coordinate: end),
                    subwayFinalStation: nil,
                    subwayDirection: nil,
                    isExpressSubway: false,
                    isLastSubway: false
                ),
            ]
        )
    }
}

/// 서버 알람 등록/삭제 실패를 무시해 로컬 스케줄(AlarmKit)까지 진행시킨다.
/// refresh는 그대로 실패시킨다 — 홈이 상태를 유지하므로 시연에 지장이 없다.
/// 단, Phase 11 변경 시뮬레이터의 주입이 보류 중이면 서버 대신 변형 AlarmInfo를 반환한다.
struct DevDemoTolerantAlarmRepository: AlarmRepository {
    let base: any AlarmRepository

    func register(lastRouteId: String) async throws {
        do { try await base.register(lastRouteId: lastRouteId) }
        catch { print("⚠️ [DEV 우회] 서버 알람 등록 실패 무시 → 로컬 스케줄 진행: \(error)") }
        // 새 세션 시작 — 변경 시뮬레이터가 이 경로를 기준으로 변형한다.
        await DevChangeSimulator.shared.noteKnownSession(routeId: lastRouteId, departureTime: nil)
    }

    func cancel(lastRouteId: String) async throws {
        do { try await base.cancel(lastRouteId: lastRouteId) }
        catch { print("⚠️ [DEV 우회] 서버 알람 삭제 실패 무시 → 로컬 취소 진행: \(error)") }
    }

    func refresh() async throws -> AlarmInfo {
        // Phase 11 검수: 보류 중 변경 주입이 있으면 서버 대신 시뮬레이터가 응답한다(1회 소비).
        if let injected = await DevChangeSimulator.shared.consumeInjectedInfo() {
            print("⚠️ [DEV 변경 시뮬레이터] 변형 AlarmInfo 반환: departure=\(String(describing: injected.departureTime))")
            return injected
        }
        let info = try await base.refresh()
        await DevChangeSimulator.shared.noteKnownSession(
            routeId: info.lastRouteId, departureTime: info.departureTime
        )
        return info
    }
}

// MARK: - Phase 11 변경 시뮬레이터 (DEV 한정 — 사람 검수의 전제)

/// 막차 변경 피기백(판정 → 알람 재스케줄 → LA alert/홈 배너)을 검수할 유일한 주입 수단.
/// 실서버가 변경을 내려줄 수 없는 동안 `DevDemoTolerantAlarmRepository.refresh()`가
/// 보류 중 주입을 소비해, 마지막으로 알려진 출발 시각 기준으로 변형된 AlarmInfo를 반환한다.
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
    /// 마지막으로 알려진 세션 — 데모 경로 생성·등록·refresh 성공·주입 적용 시 갱신된다.
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

    /// 알려진 세션의 출발 시각 — routeId가 일치할 때만 (데모 상세의 시각 정합용).
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
