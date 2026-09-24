@testable import CoreStorage
import Foundation
import Synchronization
import Testing

private final class InMemoryKeyValueStore: KeyValueStore {
    private let storage = Mutex<[String: Data]>([:])

    func data(forKey key: String) throws -> Data? { storage.withLock { $0[key] } }
    func set(_ data: Data, forKey key: String) throws { storage.withLock { $0[key] = data } }
    func removeValue(forKey key: String) throws { storage.withLock { $0[key] = nil } }
}

/// 시계를 손으로 돌린다 — 만료 검증에 실제 대기를 쓰면 테스트가 느려지고 흔들린다.
private final class Clock: @unchecked Sendable {
    private let value: Mutex<Date>

    init(_ start: Date) { value = Mutex(start) }
    // Mutex는 non-copyable이라 캡처 목록에 넣을 수 없다 — 클래스 참조(self)를 캡처한다.
    var now: @Sendable () -> Date { { self.value.withLock { $0 } } }
    func advance(_ seconds: TimeInterval) { value.withLock { $0 = $0.addingTimeInterval(seconds) } }
}

struct ExpiringCacheTests {
    private let store = InMemoryKeyValueStore()
    private let clock = Clock(Date(timeIntervalSince1970: 1_000_000))

    /// 지터 0 고정이 기본이다 — 만료 시각이 결정적이어야 경계 검증이 성립한다.
    private func makeSUT(
        ttl: Duration = .seconds(60),
        limit: Int = 10,
        jitter: @escaping @Sendable (ClosedRange<Double>) -> Double = { _ in 0 }
    ) -> ExpiringCache<String> {
        ExpiringCache(
            store: store, key: "cache", ttl: ttl, limit: limit,
            now: clock.now, jitter: jitter
        )
    }

    @Test
    func value_missingKey_returnsNil() async {
        #expect(await makeSUT().value(forKey: "a") == nil)
    }

    @Test
    func setValue_thenRead_returnsStoredValue() async throws {
        let sut = makeSUT()

        try await sut.setValue("서울역", forKey: "a")

        #expect(await sut.value(forKey: "a") == "서울역")
    }

    @Test
    func value_beforeTTL_stillHits() async throws {
        let sut = makeSUT(ttl: .seconds(60))
        try await sut.setValue("서울역", forKey: "a")

        clock.advance(59)

        #expect(await sut.value(forKey: "a") == "서울역")
    }

    @Test
    func value_afterTTL_missesAsIfAbsent() async throws {
        let sut = makeSUT(ttl: .seconds(60))
        try await sut.setValue("서울역", forKey: "a")

        clock.advance(61)

        #expect(await sut.value(forKey: "a") == nil)
    }

    /// 재저장은 멱등이다 — 같은 키가 둘로 갈라지면 상한이 실제보다 빨리 찬다.
    @Test
    func setValue_sameKeyTwice_keepsOneEntryWithLatestValue() async throws {
        let sut = makeSUT()

        try await sut.setValue("옛값", forKey: "a")
        try await sut.setValue("새값", forKey: "a")
        try await sut.setValue("b값", forKey: "b")

        #expect(await sut.value(forKey: "a") == "새값")
        #expect(await sut.value(forKey: "b") == "b값")
    }

    /// 상한은 최신순으로 자른다 — 가장 오래 안 쓴 항목이 먼저 나간다.
    @Test
    func setValue_overLimit_dropsOldest() async throws {
        let sut = makeSUT(limit: 2)

        try await sut.setValue("1", forKey: "a")
        try await sut.setValue("2", forKey: "b")
        try await sut.setValue("3", forKey: "c")

        #expect(await sut.value(forKey: "a") == nil)
        #expect(await sut.value(forKey: "b") == "2")
        #expect(await sut.value(forKey: "c") == "3")
    }

    /// 만료분 청소는 저장 시점에 일어난다 — 조회가 디스크를 건드리지 않게 하기 위해서다.
    @Test
    func setValue_prunesExpiredEntries() async throws {
        let sut = makeSUT(ttl: .seconds(60), limit: 10)
        try await sut.setValue("낡음", forKey: "a")

        clock.advance(61)
        try await sut.setValue("새것", forKey: "b")

        // 만료 항목이 남아 있었다면 상한 1짜리 캐시에서 b가 밀려났을 것이다.
        #expect(await sut.value(forKey: "a") == nil)
        #expect(await sut.value(forKey: "b") == "새것")
    }

    /// 지터는 만료를 흩는다. 최대 지터(+10%)가 걸리면 기준 TTL을 넘겨도 아직 산다 —
    /// 막차 시간대에 수천 기기의 만료가 한 점에 몰리지 않는 이유가 이것이다.
    @Test
    func setValue_positiveJitter_extendsExpiryBeyondBaseTTL() async throws {
        let sut = makeSUT(ttl: .seconds(100), jitter: { $0.upperBound })
        try await sut.setValue("서울역", forKey: "a")

        clock.advance(105)

        #expect(await sut.value(forKey: "a") == "서울역")
    }

    @Test
    func setValue_negativeJitter_expiresBeforeBaseTTL() async throws {
        let sut = makeSUT(ttl: .seconds(100), jitter: { $0.lowerBound })
        try await sut.setValue("서울역", forKey: "a")

        clock.advance(95)

        #expect(await sut.value(forKey: "a") == nil)
    }

    /// 손상된 저장 내용은 캐시 부재로 강등한다 — 다음 저장이 덮어써 자가 치유한다.
    @Test
    func value_corruptedStore_treatedAsEmpty() async throws {
        try store.set(Data("깨진 JSON".utf8), forKey: "cache")
        let sut = makeSUT()

        #expect(await sut.value(forKey: "a") == nil)
        try await sut.setValue("복구", forKey: "a")
        #expect(await sut.value(forKey: "a") == "복구")
    }

    @Test
    func removeAll_dropsEverything() async throws {
        let sut = makeSUT()
        try await sut.setValue("서울역", forKey: "a")

        try await sut.removeAll()

        #expect(await sut.value(forKey: "a") == nil)
    }
}
