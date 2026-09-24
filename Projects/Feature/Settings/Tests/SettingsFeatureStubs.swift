import Domain
import Foundation
import Synchronization

struct StubFailure: Error {}

/// 테스트 드레인 — 스텁이 즉시 resolve하므로 yield로 충분하다(Home 템플릿 패턴).
@MainActor
func waitUntil(_ predicate: () -> Bool) async {
    for _ in 0..<1000 where !predicate() {
        await Task.yield()
    }
}

final class StubGetUserProfileUseCase: GetUserProfileUseCase {
    let address: String?
    let fails: Bool

    init(address: String? = nil, fails: Bool = false) {
        self.address = address
        self.fails = fails
    }

    func execute() async throws -> UserProfile {
        if fails { throw StubFailure() }
        return UserProfile(userID: 1, providerID: nil, nickname: nil, address: address, coordinate: nil, appVersion: nil)
    }
}

struct StubCheckAppUpdateUseCase: CheckAppUpdateUseCase {
    let status: AppUpdateStatus
    func execute(currentVersion: String) async throws -> AppUpdateStatus { status }
}

struct StubSearchPlacesUseCase: SearchPlacesUseCase {
    var places: [Place] = []
    func execute(keyword: String, near coordinate: Coordinate?) async throws -> [Place] { places }
}

struct StubGetCurrentLocationUseCase: GetCurrentLocationUseCase {
    var fails = false
    func execute() async throws -> Coordinate {
        if fails { throw StubFailure() }
        return Coordinate(latitude: 37.5665, longitude: 126.9780)
    }
}

struct StubReverseGeocodeUseCase: ReverseGeocodeUseCase {
    func execute(coordinate: Coordinate) async throws -> Place {
        Place(name: "서울시청", address: "서울 중구 세종대로 110", coordinate: coordinate)
    }
}

final class SpyUpdateHomeAddressUseCase: UpdateHomeAddressUseCase {
    private let log = Mutex<[String?]>([])
    private let stored = Mutex<(any Error)?>(nil)
    var addresses: [String?] { log.withLock { $0 } }
    var error: (any Error)? {
        get { stored.withLock { $0 } }
        set { stored.withLock { $0 = newValue } }
    }

    func execute(address: String?, coordinate: Coordinate) async throws {
        log.withLock { $0.append(address) }
        if let error { throw error }
    }
}
