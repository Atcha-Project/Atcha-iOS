@testable import AtchaData
import CoreStorage
import Domain
import Foundation
import Synchronization
import Testing

private final class InMemoryKeyValueStore: KeyValueStore {
    private let storage = Mutex<[String: Data]>([:])

    func data(forKey key: String) throws -> Data? {
        storage.withLock { $0[key] }
    }

    func set(_ data: Data, forKey key: String) throws {
        storage.withLock { $0[key] = data }
    }

    func removeValue(forKey key: String) throws {
        storage.withLock { $0[key] = nil }
    }
}

private extension Place {
    static func fixture(
        name: String = "홍대입구역",
        address: String = "서울 마포구",
        latitude: Double = 37.556748,
        longitude: Double = 126.923643
    ) -> Place {
        Place(name: name, address: address, coordinate: Coordinate(latitude: latitude, longitude: longitude))
    }
}

struct RecentSearchRepositoryImplTests {
    private let store = InMemoryKeyValueStore()
    private var sut: RecentSearchRepositoryImpl { RecentSearchRepositoryImpl(store: store) }

    @Test
    func recentSearches_emptyStore_returnsEmpty() async throws {
        #expect(try await sut.recentSearches() == [])
    }

    @Test
    func save_thenFetch_returnsPlace() async throws {
        try await sut.save(.fixture())
        #expect(try await sut.recentSearches() == [.fixture()])
    }

    @Test
    func save_ordersNewestFirst() async throws {
        try await sut.save(.fixture(name: "첫번째"))
        try await sut.save(.fixture(name: "두번째"))
        try await sut.save(.fixture(name: "세번째"))
        #expect(try await sut.recentSearches().map(\.name) == ["세번째", "두번째", "첫번째"])
    }

    @Test
    func save_duplicate_movesToFrontWithoutDuplicate() async throws {
        try await sut.save(.fixture(name: "홍대입구역"))
        try await sut.save(.fixture(name: "서울역"))
        try await sut.save(.fixture(name: "홍대입구역"))
        #expect(try await sut.recentSearches().map(\.name) == ["홍대입구역", "서울역"])
    }

    @Test
    func save_eleventhItem_dropsOldest_capsAtTen() async throws {
        for index in 1 ... 11 {
            try await sut.save(.fixture(name: "역\(index)"))
        }
        let names = try await sut.recentSearches().map(\.name)
        #expect(names.count == 10)
        #expect(names.first == "역11")
        #expect(!names.contains("역1"))
    }

    @Test
    func remove_deletesOnlyMatchingPlace() async throws {
        try await sut.save(.fixture(name: "홍대입구역"))
        try await sut.save(.fixture(name: "서울역"))
        try await sut.remove(.fixture(name: "홍대입구역"))
        #expect(try await sut.recentSearches().map(\.name) == ["서울역"])
    }

    @Test
    func remove_absentPlace_isNoop() async throws {
        try await sut.save(.fixture(name: "서울역"))
        try await sut.remove(.fixture(name: "없는역"))
        #expect(try await sut.recentSearches().map(\.name) == ["서울역"])
    }

    @Test
    func recentSearches_corruptStoredData_returnsEmpty() async throws {
        try store.set(Data("not json".utf8), forKey: "recentSearches")
        #expect(try await sut.recentSearches() == [])
    }

    @Test
    func save_persistsAcrossRepositoryInstances() async throws {
        try await RecentSearchRepositoryImpl(store: store).save(.fixture())
        let other = RecentSearchRepositoryImpl(store: store)
        #expect(try await other.recentSearches() == [.fixture()])
    }

    /// 회귀: save가 read-modify-write라 값 타입이던 시절에는 동시 저장 시 나중 쓰기가
    /// 먼저 쓰기를 통째로 덮어써 1건이 사라졌다(홈의 목적지 승격 저장 ↔ 검색 화면 저장).
    ///
    /// **반드시 단일 인스턴스로 검증한다** — actor 격리는 인스턴스 단위라 `sut`(매번 새
    /// 인스턴스를 만드는 computed property)로는 직렬화가 성립하지 않는다. 실제 앱도
    /// `AppDIContainer`가 repository를 1회 생성해 홈·검색이 공유하므로 이쪽이 실조건이다.
    @Test
    func save_concurrentWrites_keepsBoth() async throws {
        let shared = RecentSearchRepositoryImpl(store: store)

        await withTaskGroup(of: Void.self) { group in
            for name in ["서울역", "홍대입구역", "강남역", "잠실역"] {
                group.addTask { try? await shared.save(.fixture(name: name)) }
            }
        }

        let names = try await shared.recentSearches().map(\.name)
        #expect(names.count == 4)
        #expect(Set(names) == ["서울역", "홍대입구역", "강남역", "잠실역"])
    }
}
