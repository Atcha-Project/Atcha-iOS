@testable import CoreStorage
import Foundation
import Synchronization
import Testing

private final class CountingKeyValueStore: KeyValueStore {
    private let storage = Mutex<[String: Data]>([:])
    private let reads = Mutex(0)
    private let failOnSet: Bool

    init(failOnSet: Bool = false) {
        self.failOnSet = failOnSet
    }

    var readCount: Int { reads.withLock { $0 } }

    func data(forKey key: String) throws -> Data? {
        reads.withLock { $0 += 1 }
        return storage.withLock { $0[key] }
    }

    func set(_ data: Data, forKey key: String) throws {
        if failOnSet { throw StoreError.rejected }
        storage.withLock { $0[key] = data }
    }

    func removeValue(forKey key: String) throws {
        storage.withLock { $0[key] = nil }
    }

    /// 스키마 불일치·파손 재현용 — 프로토콜 밖에서 직접 심는다.
    func plant(_ raw: Data, forKey key: String) {
        storage.withLock { $0[key] = raw }
    }
}

private enum StoreError: Error { case rejected }

private struct Session: Codable, Equatable {
    var routeID: String
    var walkSeconds: Int
}

struct DocumentStoreTests {
    private let store = CountingKeyValueStore()
    private func makeSUT() -> DocumentStore<Session> {
        DocumentStore(store: store, key: "session")
    }

    @Test
    func load_emptyStore_returnsNil() async {
        #expect(await makeSUT().load() == nil)
    }

    @Test
    func save_thenLoad_roundTrips() async throws {
        let sut = makeSUT()
        let session = Session(routeID: "R1", walkSeconds: 300)

        try await sut.save(session)

        #expect(await sut.load() == session)
    }

    /// 캐시가 부재도 기억해야 한다 — 없는 문서를 매번 디스크에서 다시 확인하면
    /// 프레임마다 읽는 호출자에게 비용이 된다.
    @Test
    func load_absentDocument_readsDiskOnce() async {
        let sut = makeSUT()

        _ = await sut.load()
        _ = await sut.load()
        _ = await sut.load()

        #expect(store.readCount == 1)
    }

    @Test
    func save_thenLoad_doesNotTouchDisk() async throws {
        let sut = makeSUT()
        try await sut.save(Session(routeID: "R1", walkSeconds: 300))
        let before = store.readCount

        _ = await sut.load()

        #expect(store.readCount == before)
    }

    /// 스키마가 바뀌었거나 파일이 깨지면 부재로 강등한다(자가 치유 규약).
    @Test
    func load_corruptData_returnsNil() async {
        store.plant(Data("not json".utf8), forKey: "session")

        #expect(await makeSUT().load() == nil)
    }

    @Test
    func clear_removesDocument() async throws {
        let sut = makeSUT()
        try await sut.save(Session(routeID: "R1", walkSeconds: 300))

        try await sut.clear()

        #expect(await sut.load() == nil)
    }

    /// mutate는 읽고-고쳐-쓰기를 actor 안에서 한 번에 끝낸다.
    @Test
    func mutate_appliesTransformAndPersists() async throws {
        let sut = makeSUT()
        try await sut.save(Session(routeID: "R1", walkSeconds: 300))

        try await sut.mutate { current in
            guard var next = current else { return nil }
            next.walkSeconds = 600
            return next
        }

        #expect(await sut.load() == Session(routeID: "R1", walkSeconds: 600))
    }

    @Test
    func mutate_returningNil_clearsDocument() async throws {
        let sut = makeSUT()
        try await sut.save(Session(routeID: "R1", walkSeconds: 300))

        try await sut.mutate { _ in nil }

        #expect(await sut.load() == nil)
    }

    /// 저장 실패 시 캐시가 갱신되면 살아 있는 인스턴스가 디스크에 없는 값을 답한다.
    @Test
    func save_storeFailure_propagatesAndKeepsCacheConsistent() async {
        let failing = CountingKeyValueStore(failOnSet: true)
        let sut = DocumentStore<Session>(store: failing, key: "session")

        await #expect(throws: StoreError.self) {
            try await sut.save(Session(routeID: "R1", walkSeconds: 300))
        }

        #expect(await sut.load() == nil)
    }
}
