import Foundation

/// 유효기간이 있는 키-값 캐시. **서버에서 다시 받을 수 있는 응답 전용**이다 —
/// 디코딩 실패도 캐시 부재로 강등하므로, 잃으면 안 되는 값은 여기 담지 않는다
/// (그쪽은 `DocumentStore`/`CollectionStore`).
///
/// `actor`인 이유는 `CollectionStore`와 같다. 조회·저장이 전부 read-modify-write라
/// 값 타입으로 두면 동시 저장이 서로를 덮어쓴다. 격리는 **인스턴스 단위**이므로
/// 조합 루트에서 1회 생성해 공유해야 한다.
///
/// **만료에 지터를 넣는 이유.** 같은 TTL로 한꺼번에 채워진 항목은 한꺼번에 만료된다.
/// 이 앱의 실제 피크는 막차 시간대(23:30~00:30)에 수천 기기가 동시에 앱을 여는
/// 순간이라, 만료가 몰리면 그 순간 캐시가 통째로 무력해지고 요청이 서버에 몰린다.
/// 항목마다 ±`jitterRatio`를 흩어 그 동시성을 깬다.
public actor ExpiringCache<Value: Codable & Sendable> {
    private struct Entry: Codable, Sendable {
        let key: String
        let value: Value
        let expiresAt: Date
    }

    private let store: any KeyValueStore
    private let storageKey: String
    private let ttlSeconds: Double
    private let limit: Int
    private let jitterRatio: Double
    private let now: @Sendable () -> Date
    /// 지터 배수를 주입으로 받는 이유: 난수를 타입 안에서 뽑으면 만료 시각이
    /// 테스트에서 결정적이지 않다(`now` 주입과 같은 이유).
    private let jitter: @Sendable (ClosedRange<Double>) -> Double

    private var cached: [Entry]?

    /// - Parameters:
    ///   - ttl: 기준 유효기간. 실제 만료는 여기에 ±`jitterRatio`가 곱해진다.
    ///   - limit: 최신순 상한. 초과분은 저장 시 잘린다.
    public init(
        store: any KeyValueStore,
        key: String,
        ttl: Duration,
        limit: Int,
        jitterRatio: Double = 0.1,
        now: @escaping @Sendable () -> Date = Date.init,
        jitter: @escaping @Sendable (ClosedRange<Double>) -> Double = { Double.random(in: $0) }
    ) {
        self.store = store
        storageKey = key
        ttlSeconds = Double(ttl.components.seconds) + Double(ttl.components.attoseconds) / 1e18
        self.limit = limit
        self.jitterRatio = jitterRatio
        self.now = now
        self.jitter = jitter
    }

    /// 만료된 항목은 부재로 답한다. 만료분 청소는 저장 시점에 한 번에 하므로
    /// 조회는 디스크를 건드리지 않는다.
    public func value(forKey key: String) -> Value? {
        let moment = now()
        return entries().first { $0.key == key && $0.expiresAt > moment }?.value
    }

    /// 같은 키의 기존 항목을 걷어내고 맨 앞에 넣는다 — 재저장이 멱등이고,
    /// 최신순 상한이 LRU처럼 동작한다.
    public func setValue(_ value: Value, forKey key: String) throws {
        let moment = now()
        let factor = 1 + jitter(-jitterRatio...jitterRatio)
        let entry = Entry(key: key, value: value, expiresAt: moment.addingTimeInterval(ttlSeconds * factor))

        var items = entries()
        items.removeAll { $0.key == key || $0.expiresAt <= moment }
        items.insert(entry, at: 0)
        try persist(Array(items.prefix(limit)))
    }

    public func removeAll() throws {
        try store.removeValue(forKey: storageKey)
        cached = []
    }

    private func entries() -> [Entry] {
        if let cached { return cached }
        let value = (try? store.value([Entry].self, forKey: storageKey)) ?? []
        cached = value
        return value
    }

    /// 디스크와 메모리 캐시를 같은 지점에서 갱신한다 — 한쪽만 바꾸면 살아 있는
    /// 인스턴스가 낡은 값을 답한다.
    private func persist(_ items: [Entry]) throws {
        try store.setValue(items, forKey: storageKey)
        cached = items
    }
}
