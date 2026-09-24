import Foundation

/// 상한이 있는 최신순 목록 저장소. 최근 검색·경로 캐시처럼 "최근 N건만 남기는" 목록을
/// 다룬다.
///
/// `actor`인 이유가 `DocumentStore`보다 더 직접적이다. 목록 갱신은 전부
/// read-modify-write이고, 값 타입 저장소로 이걸 하면 **동시 저장 시 나중 쓰기가 먼저
/// 쓰기를 통째로 덮어써 항목이 조용히 사라진다.** `RecentSearchRepositoryImpl`에서
/// 실제로 발생한 버그이고(단일 인스턴스에 4건 동시 저장 → 2건 유실), 그 수정이 이
/// 타입의 존재 이유다.
///
/// 격리가 **인스턴스 단위**임에 주의한다 — 같은 키를 여러 인스턴스가 쓰면 직렬화가
/// 성립하지 않는다. 조합 루트에서 1회 생성해 공유해야 한다.
public actor CollectionStore<Element: Codable & Sendable> {
    private let store: any KeyValueStore
    private let key: String
    private let limit: Int
    private var cached: [Element]?

    /// - Parameter limit: 최신순 상한. 초과분은 저장 시 잘린다.
    public init(store: any KeyValueStore, key: String, limit: Int) {
        self.store = store
        self.key = key
        self.limit = limit
    }

    /// 디코딩 실패는 빈 목록으로 강등한다 — 일회성 캐시라 다음 쓰기가 덮어써 자가 치유한다.
    public func all() -> [Element] {
        if let cached { return cached }
        let value = (try? store.value([Element].self, forKey: key)) ?? []
        cached = value
        return value
    }

    /// 맨 앞에 넣는다. `isDuplicate`로 기존 항목을 먼저 걷어내므로 재저장이 멱등이다
    /// (같은 항목을 다시 넣으면 순서만 최신으로 올라간다).
    public func insert(_ element: Element, isDuplicate: (Element) -> Bool) throws {
        var items = all()
        items.removeAll(where: isDuplicate)
        items.insert(element, at: 0)
        try persist(Array(items.prefix(limit)))
    }

    public func remove(where shouldRemove: (Element) -> Bool) throws {
        var items = all()
        items.removeAll(where: shouldRemove)
        try persist(items)
    }

    public func first(where predicate: (Element) -> Bool) -> Element? {
        all().first(where: predicate)
    }

    public func clear() throws {
        try store.removeValue(forKey: key)
        cached = []
    }

    /// 디스크와 캐시를 같은 지점에서 갱신한다 — 한쪽만 바꾸면 살아 있는 인스턴스가
    /// 낡은 값을 답한다.
    private func persist(_ items: [Element]) throws {
        try store.setValue(items, forKey: key)
        cached = items
    }
}
