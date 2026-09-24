@testable import CoreStorage
import Foundation
import Testing

private struct Payload: Codable, Equatable {
    var id: Int
    var text: String
}

/// 실제 파일 시스템을 쓴다 — 원자적 쓰기·백업 제외는 모킹하면 검증 의미가 없다.
/// 테스트마다 고유 네임스페이스를 쓰고 끝나면 지운다(swift-testing은 기본 병렬 실행).
struct FileKeyValueStoreTests {
    private let namespace: String
    private let sut: FileKeyValueStore

    init() {
        namespace = "FileKeyValueStoreTests-\(UUID().uuidString)"
        sut = FileKeyValueStore(namespace: .durable(namespace))
    }

    private func cleanUp() {
        guard let support = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return }
        try? FileManager.default.removeItem(
            at: support.appendingPathComponent(namespace, isDirectory: true)
        )
    }

    @Test
    func data_absentKey_returnsNil() throws {
        defer { cleanUp() }
        #expect(try sut.data(forKey: "missing") == nil)
    }

    @Test
    func set_thenData_roundTrips() throws {
        defer { cleanUp() }
        let raw = Data("hello".utf8)

        try sut.set(raw, forKey: "greeting")

        #expect(try sut.data(forKey: "greeting") == raw)
    }

    @Test
    func codableRoundTrip_viaKeyValueStoreExtension() throws {
        defer { cleanUp() }
        let payload = Payload(id: 7, text: "막차")

        try sut.setValue(payload, forKey: "payload")

        #expect(try sut.value(Payload.self, forKey: "payload") == payload)
    }

    @Test
    func set_overwritesExistingValue() throws {
        defer { cleanUp() }
        try sut.set(Data("first".utf8), forKey: "k")

        try sut.set(Data("second".utf8), forKey: "k")

        #expect(try sut.data(forKey: "k") == Data("second".utf8))
    }

    @Test
    func removeValue_deletesFile() throws {
        defer { cleanUp() }
        try sut.set(Data("x".utf8), forKey: "k")

        try sut.removeValue(forKey: "k")

        #expect(try sut.data(forKey: "k") == nil)
    }

    /// 부재 키 삭제는 오류가 아니다 — 멱등이어야 정리 경로가 단순해진다.
    @Test
    func removeValue_absentKey_isNoop() throws {
        defer { cleanUp() }
        try sut.removeValue(forKey: "missing")
    }

    /// 키가 파일명이 되므로 경로 구분자가 디렉터리를 만들거나 상위로 탈출하면 안 된다.
    @Test
    func keysWithPathSeparators_stayInsideNamespace() throws {
        defer { cleanUp() }
        try sut.set(Data("a".utf8), forKey: "alarm/session")
        try sut.set(Data("b".utf8), forKey: "../escape")

        #expect(try sut.data(forKey: "alarm/session") == Data("a".utf8))
        #expect(try sut.data(forKey: "../escape") == Data("b".utf8))
    }

    /// 캐시 네임스페이스는 백업에서 제외된다 — 다시 받을 수 있는 데이터가 사용자의
    /// 백업 용량을 쓰면서 저장 공간이 부족해도 정리되지 않는 조합을 피한다.
    @Test
    func cacheNamespace_isExcludedFromBackup() throws {
        let cacheNamespace = "FileKeyValueStoreTests-cache-\(UUID().uuidString)"
        let cache = FileKeyValueStore(namespace: .cache(cacheNamespace))
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = support.appendingPathComponent(cacheNamespace, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try cache.set(Data("x".utf8), forKey: "k")

        let excluded = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
            .isExcludedFromBackup
        #expect(excluded == true)
    }

    @Test
    func durableNamespace_isNotExcludedFromBackup() throws {
        defer { cleanUp() }
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = support.appendingPathComponent(namespace, isDirectory: true)

        try sut.set(Data("x".utf8), forKey: "k")

        let excluded = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
            .isExcludedFromBackup
        #expect(excluded != true)
    }
}
