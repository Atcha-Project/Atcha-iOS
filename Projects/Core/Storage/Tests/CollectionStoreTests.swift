@testable import CoreStorage
import Foundation
import Synchronization
import Testing

private final class InMemoryKeyValueStore: KeyValueStore {
    private let storage = Mutex<[String: Data]>([:])

    func data(forKey key: String) throws -> Data? { storage.withLock { $0[key] } }
    func set(_ data: Data, forKey key: String) throws { storage.withLock { $0[key] = data } }
    func removeValue(forKey key: String) throws { storage.withLock { $0[key] = nil } }
    func plant(_ raw: Data, forKey key: String) { storage.withLock { $0[key] = raw } }
}

private struct Entry: Codable, Equatable {
    var name: String
}

struct CollectionStoreTests {
    private let store = InMemoryKeyValueStore()
    private func makeSUT(limit: Int = 10) -> CollectionStore<Entry> {
        CollectionStore(store: store, key: "recents", limit: limit)
    }

    @Test
    func all_emptyStore_returnsEmpty() async {
        #expect(await makeSUT().all().isEmpty)
    }

    @Test
    func insert_putsNewestFirst() async throws {
        let sut = makeSUT()

        try await sut.insert(Entry(name: "A")) { $0.name == "A" }
        try await sut.insert(Entry(name: "B")) { $0.name == "B" }

        #expect(await sut.all().map(\.name) == ["B", "A"])
    }

    /// 같은 항목 재저장은 멱등이어야 한다 — 중복이 쌓이지 않고 순서만 최신으로 올라간다.
    @Test
    func insert_duplicate_movesToFrontWithoutGrowing() async throws {
        let sut = makeSUT()
        try await sut.insert(Entry(name: "A")) { $0.name == "A" }
        try await sut.insert(Entry(name: "B")) { $0.name == "B" }

        try await sut.insert(Entry(name: "A")) { $0.name == "A" }

        #expect(await sut.all().map(\.name) == ["A", "B"])
    }

    @Test
    func insert_beyondLimit_dropsOldest() async throws {
        let sut = makeSUT(limit: 3)

        for name in ["A", "B", "C", "D"] {
            try await sut.insert(Entry(name: name)) { $0.name == name }
        }

        #expect(await sut.all().map(\.name) == ["D", "C", "B"])
    }

    /// 이 타입의 존재 이유 — 값 타입 저장소에서 동시 저장 시 나중 쓰기가 먼저 쓰기를
    /// 덮어써 항목이 사라지던 버그(`RecentSearchRepositoryImpl`)를 막는다.
    /// **단일 인스턴스로 검증한다** — actor 격리는 인스턴스 단위다.
    @Test
    func insert_concurrentWrites_keepsAll() async throws {
        let sut = makeSUT()
        let names = ["A", "B", "C", "D", "E"]

        await withTaskGroup(of: Void.self) { group in
            for name in names {
                group.addTask { try? await sut.insert(Entry(name: name)) { $0.name == name } }
            }
        }

        let stored = await sut.all().map(\.name)
        #expect(stored.count == names.count)
        #expect(Set(stored) == Set(names))
    }

    @Test
    func remove_deletesMatching() async throws {
        let sut = makeSUT()
        try await sut.insert(Entry(name: "A")) { $0.name == "A" }
        try await sut.insert(Entry(name: "B")) { $0.name == "B" }

        try await sut.remove { $0.name == "A" }

        #expect(await sut.all().map(\.name) == ["B"])
    }

    @Test
    func remove_absentElement_isNoop() async throws {
        let sut = makeSUT()
        try await sut.insert(Entry(name: "A")) { $0.name == "A" }

        try await sut.remove { $0.name == "없음" }

        #expect(await sut.all().map(\.name) == ["A"])
    }

    @Test
    func first_findsMatching() async throws {
        let sut = makeSUT()
        try await sut.insert(Entry(name: "A")) { $0.name == "A" }

        #expect(await sut.first { $0.name == "A" } == Entry(name: "A"))
        #expect(await sut.first { $0.name == "Z" } == nil)
    }

    @Test
    func clear_emptiesList() async throws {
        let sut = makeSUT()
        try await sut.insert(Entry(name: "A")) { $0.name == "A" }

        try await sut.clear()

        #expect(await sut.all().isEmpty)
    }

    /// 파손 데이터는 빈 목록으로 강등 — 다음 쓰기가 덮어써 자가 치유한다.
    @Test
    func all_corruptData_returnsEmpty() async {
        store.plant(Data("not json".utf8), forKey: "recents")

        #expect(await makeSUT().all().isEmpty)
    }
}
