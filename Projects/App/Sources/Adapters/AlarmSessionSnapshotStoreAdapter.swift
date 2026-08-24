import CoreStorage
import Domain
import Foundation

/// Domain `AlarmSessionSnapshotStore` → CoreStorage(UserDefaults 백엔드) 어댑터 (Phase 14).
/// 스냅샷은 재실행 브리지이지 정본이 아니다 — 저장·삭제 실패는 조용히 흡수하고(다음
/// 등록/sync가 자가치유), 필드 추가 등으로 인한 디코딩 실패도 nil로 무해화한다
/// (최근 검색 저장소의 자가치유 패턴 재사용).
struct AlarmSessionSnapshotStoreAdapter: AlarmSessionSnapshotStore {
    private static let storageKey = "alarm.sessionSnapshot"

    private let store: any KeyValueStore

    init(store: any KeyValueStore = UserDefaultsKeyValueStore()) {
        self.store = store
    }

    func load() async -> AlarmSessionSnapshot? {
        (try? store.value(AlarmSessionSnapshot.self, forKey: Self.storageKey)) ?? nil
    }

    func save(_ snapshot: AlarmSessionSnapshot) async {
        try? store.setValue(snapshot, forKey: Self.storageKey)
    }

    func clear() async {
        try? store.removeValue(forKey: Self.storageKey)
    }
}
