import CoreStorage
import Domain

public struct RecentSearchRepositoryImpl: RecentSearchRepository {
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
