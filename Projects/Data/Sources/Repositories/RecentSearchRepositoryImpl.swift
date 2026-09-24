import CoreStorage
import Domain

/// `actor`인 이유: save/remove가 전부 read-modify-write다. 값 타입이던 시절에는
/// 홈의 목적지 승격 저장과 검색 화면의 저장이 겹치면 나중 쓰기가 먼저 쓰기를
/// 통째로 덮어써 최근 검색 1건이 조용히 사라졌다(lost update). 단일 writer를
/// 타입으로 강제해 막는다.
public actor RecentSearchRepositoryImpl: RecentSearchRepository {
    private let store: any KeyValueStore
    private let maxCount: Int
    private let storageKey = "recentSearches"

    public init(store: any KeyValueStore, maxCount: Int = 10) {
        self.store = store
        self.maxCount = maxCount
    }

    public func recentSearches() async throws -> [Place] {
        loadRecords().map { $0.toEntity() }
    }

    public func save(_ place: Place) async throws {
        var records = loadRecords()
        records.removeAll { $0.toEntity() == place }
        records.insert(RecentSearchRecordDTO(place), at: 0)
        try store.setValue(Array(records.prefix(maxCount)), forKey: storageKey)
    }

    public func remove(_ place: Place) async throws {
        var records = loadRecords()
        records.removeAll { $0.toEntity() == place }
        try store.setValue(records, forKey: storageKey)
    }

    /// 부재·손상 데이터는 빈 목록으로 — 일회성 캐시라 다음 save가 덮어써 자가 치유한다.
    private func loadRecords() -> [RecentSearchRecordDTO] {
        (try? store.value([RecentSearchRecordDTO].self, forKey: storageKey)) ?? []
    }
}
