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
            return [Self.demoRoute(start: start, end: end)]
        }
    }

    func lastRoute(id: String) async throws -> LastRoute {
        do { return try await base.lastRoute(id: id) }
        catch {
            print("⚠️ [DEV 우회] 경로 상세 실패 → 데모 경로 반환: \(error)")
            return Self.demoRoute(
                start: Coordinate(latitude: 37.4979, longitude: 127.0276),
                end: Coordinate(latitude: 37.4853, longitude: 126.9015)
            )
        }
    }

    /// 발화 검증을 빠르게 하려고 출발 시각을 3분 뒤로 둔다 (알람은 출발 시각에 울린다).
    private static func demoRoute(start: Coordinate, end: Coordinate) -> LastRoute {
        let departure = Date().addingTimeInterval(3 * 60)
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
struct DevDemoTolerantAlarmRepository: AlarmRepository {
    let base: any AlarmRepository

    func register(lastRouteId: String) async throws {
        do { try await base.register(lastRouteId: lastRouteId) }
        catch { print("⚠️ [DEV 우회] 서버 알람 등록 실패 무시 → 로컬 스케줄 진행: \(error)") }
    }

    func cancel(lastRouteId: String) async throws {
        do { try await base.cancel(lastRouteId: lastRouteId) }
        catch { print("⚠️ [DEV 우회] 서버 알람 삭제 실패 무시 → 로컬 취소 진행: \(error)") }
    }

    func refresh() async throws -> AlarmInfo {
        try await base.refresh()
    }
}
#endif
