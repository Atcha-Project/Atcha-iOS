import Foundation

/// 단일 Codable 문서를 읽고 쓰는 저장소. "한 개짜리 레코드"를 다루는 곳에서
/// `KeyValueStore`를 직접 쓰는 대신 이걸 쓴다.
///
/// `actor`인 이유: `KeyValueStore`가 `Data`만 다루므로 부분 갱신을 하려면 호출자가
/// read-modify-write를 직접 해야 하고, 그게 lost update의 원인이 된다
/// (`RecentSearchRepositoryImpl`에서 실제로 발생했다). 단일 writer를 타입으로 강제한다.
///
/// 메모리 캐시를 함께 두는 이유: 같은 문서를 프레임마다 읽는 호출자가 있어도 디스크
/// 왕복이 한 번뿐이어야 한다. 캐시와 디스크는 **항상 같은 트랜잭션에서** 갱신한다 —
/// 한쪽만 갱신하면 살아 있는 인스턴스가 낡은 값을 계속 답한다.
public actor DocumentStore<Document: Codable & Sendable> {
    private let store: any KeyValueStore
    private let key: String
    /// `.some(nil)` = 부재를 확인함, `.none` = 아직 디스크를 안 읽음.
    /// 이 구분이 없으면 "값이 없는 문서"를 매번 디스크에서 다시 확인하게 된다.
    private var cached: Document??

    public init(store: any KeyValueStore, key: String) {
        self.store = store
        self.key = key
    }

    /// 디코딩 실패를 부재로 강등한다 — 스키마가 바뀌었거나 파일이 깨진 경우,
    /// 다음 저장이 덮어써 자가 치유하는 것이 이 계층의 규약이다(레거시 실측 정책).
    public func load() -> Document? {
        if let cached { return cached }
        let value = try? store.value(Document.self, forKey: key)
        cached = .some(value)
        return value
    }

    public func save(_ document: Document) throws {
        try store.setValue(document, forKey: key)
        cached = .some(document)
    }

    /// 읽고-고쳐-쓰기를 actor 안에서 한 번에 끝낸다. 호출자가 load→save로 나눠 하면
    /// 그 사이에 다른 쓰기가 끼어들 수 있다.
    @discardableResult
    public func mutate(_ transform: (Document?) -> Document?) throws -> Document? {
        let next = transform(load())
        if let next {
            try save(next)
        } else {
            try clear()
        }
        return next
    }

    public func clear() throws {
        try store.removeValue(forKey: key)
        cached = .some(nil)
    }
}
