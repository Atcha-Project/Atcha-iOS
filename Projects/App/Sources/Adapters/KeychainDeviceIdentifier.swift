import CoreStorage
import Domain
import Foundation

/// 게스트 계정 키 — 키체인은 앱 삭제 후에도 남으므로 재설치해도 같은 게스트 회원으로 이어진다
/// (identifierForVendor는 같은 벤더 앱이 전부 지워지면 바뀐다).
struct KeychainDeviceIdentifier: DeviceIdentifierProviding {
    private static let key = "guest.deviceID"
    private let store: any KeyValueStore

    init(store: any KeyValueStore = KeychainStore()) {
        self.store = store
    }

    func deviceID() throws -> String {
        if let data = try store.data(forKey: Self.key), let existing = String(data: data, encoding: .utf8) {
            return existing
        }
        let created = UUID().uuidString
        try store.set(Data(created.utf8), forKey: Self.key)
        return created
    }
}
