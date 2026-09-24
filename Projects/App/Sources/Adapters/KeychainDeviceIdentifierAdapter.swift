import CoreStorage
import Domain
import Foundation
import UIKit

/// 게스트 계정의 신원(deviceId) 제공자.
///
/// IDFV를 그대로 쓰지 않는 이유: IDFV는 같은 개발사 앱을 **전부 삭제한 뒤 재설치하면
/// 값이 바뀐다**. 서버는 deviceId로 게스트 계정을 되찾아주므로(토큰이 모두 죽어도
/// /auth/guest 재호출로 같은 계정 복귀), 값이 바뀌면 기존 계정의 알림 설정·검색 이력에
/// 영구히 접근할 수 없게 된다. 최초 1회 읽은 IDFV를 키체인에 고정해 재설치를 견딘다
/// (키체인 항목은 앱 삭제 후에도 잔존한다).
struct KeychainDeviceIdentifierAdapter: DeviceIdentifierProviding {
    private enum Key {
        static let deviceID = "deviceId"
    }

    private let store: any KeyValueStore

    init(store: any KeyValueStore = KeychainStore()) {
        self.store = store
    }

    func currentDeviceID() async -> String {
        if let stored = storedDeviceID() { return stored }
        let identifier = await freshIdentifier()
        // 저장 실패는 치명적이지 않다 — 이번 호출은 유효한 값을 돌려주고,
        // 다음 실행에서 IDFV를 다시 읽어 같은 값으로 복구될 가능성이 높다.
        try? store.set(Data(identifier.utf8), forKey: Key.deviceID)
        return identifier
    }

    private func storedDeviceID() -> String? {
        guard let data = try? store.data(forKey: Key.deviceID) else { return nil }
        let value = String(decoding: data, as: UTF8.self)
        return value.isEmpty ? nil : value
    }

    /// IDFV는 기기가 잠긴 직후 등 드물게 nil이다 — 그때는 임의 UUID로 계정을 열고
    /// 키체인 고정에 맡긴다(서버 입장에선 새 게스트, 이후로는 안정).
    @MainActor
    private func freshIdentifier() async -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}
