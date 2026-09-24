@testable import AtchaV2
import CoreStorage
import Foundation
import Synchronization
import Testing

/// 키체인 대신 쓰는 인메모리 저장소 — 테스트가 실제 키체인을 건드리지 않게 한다.
private final class InMemoryKeyValueStore: KeyValueStore {
    private let storage = Mutex<[String: Data]>([:])
    private let failOnSet: Bool

    init(seed: [String: Data] = [:], failOnSet: Bool = false) {
        storage.withLock { $0 = seed }
        self.failOnSet = failOnSet
    }

    func data(forKey key: String) throws -> Data? { storage.withLock { $0[key] } }

    func set(_ data: Data, forKey key: String) throws {
        if failOnSet { throw KeychainError.unexpectedStatus(-1) }
        storage.withLock { $0[key] = data }
    }

    func removeValue(forKey key: String) throws { storage.withLock { $0[key] = nil } }
}

struct KeychainDeviceIdentifierAdapterTests {
    /// 핵심 계약: 저장된 값이 있으면 IDFV를 다시 읽지 않는다. 게스트 계정의 신원이
    /// 앱 재설치(IDFV 변경)로 바뀌면 기존 계정에 영영 못 돌아가기 때문이다.
    @Test
    func currentDeviceID_storedValueWins() async {
        let store = InMemoryKeyValueStore(seed: ["deviceId": Data("PINNED-ID".utf8)])
        let sut = KeychainDeviceIdentifierAdapter(store: store)

        #expect(await sut.currentDeviceID() == "PINNED-ID")
    }

    /// 최초 실행: 값을 만들어 저장하고, 이후 호출은 저장된 값을 그대로 돌려준다.
    @Test
    func currentDeviceID_firstRun_persistsAndStaysStable() async throws {
        let store = InMemoryKeyValueStore()
        let sut = KeychainDeviceIdentifierAdapter(store: store)

        let first = await sut.currentDeviceID()
        #expect(!first.isEmpty)

        let persisted = try #require(try store.data(forKey: "deviceId"))
        #expect(String(decoding: persisted, as: UTF8.self) == first)
        #expect(await sut.currentDeviceID() == first)
    }

    /// 빈 문자열이 저장돼 있으면 부재로 취급하고 새로 만든다(빈 deviceId 전송 방지).
    @Test
    func currentDeviceID_emptyStoredValue_treatedAsMissing() async {
        let store = InMemoryKeyValueStore(seed: ["deviceId": Data()])
        let sut = KeychainDeviceIdentifierAdapter(store: store)

        #expect(await !sut.currentDeviceID().isEmpty)
    }

    /// 저장 실패는 치명적이지 않다 — 이번 호출은 유효한 값을 돌려줘야 한다.
    @Test
    func currentDeviceID_storeFailure_stillReturnsIdentifier() async {
        let store = InMemoryKeyValueStore(failOnSet: true)
        let sut = KeychainDeviceIdentifierAdapter(store: store)

        #expect(await !sut.currentDeviceID().isEmpty)
    }
}
