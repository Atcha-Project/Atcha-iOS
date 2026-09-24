import Foundation

/// 파일 기반 `KeyValueStore`. 키 하나가 파일 하나다.
///
/// `UserDefaultsKeyValueStore`와 나누는 기준은 **값의 크기**다. UserDefaults는 첫 접근에
/// plist 전체를 메모리로 올리므로 큰 값을 담으면 앱 시작 비용이 된다. 판단선은 단일 값
/// 4KB — 그 이상은 이쪽을 쓴다(경로 캐시 10건 ≈ 20KB가 여기 해당).
///
/// 쓰기는 `.atomic`이다. 원자적 교체가 아니면 앱이 쓰는 중에 죽었을 때 반쯤 쓰인 JSON이
/// 남고, 다음 실행의 디코딩이 실패한다.
// FileManager는 문서화된 thread-safe지만 SDK가 Sendable로 표기하지 않아 @unchecked가
// 필요하다 — UserDefaultsKeyValueStore와 같은 이유·같은 처리다.
public struct FileKeyValueStore: KeyValueStore, @unchecked Sendable {
    /// 저장 위치와 백업 정책을 함께 정한다 — 둘은 따로 정할 수 있는 값이 아니다.
    public enum Namespace: Sendable {
        /// 다시 만들 수 없는 값(세션 로컬 사실 등). 백업 대상.
        case durable(String)
        /// 서버에서 다시 받을 수 있는 값. **백업에서 제외**한다 — 사용자의 백업 용량을
        /// 쓰면서 저장 공간이 부족해도 정리되지 않는 최악의 조합을 피한다.
        case cache(String)

        var directoryName: String {
            switch self {
            case let .durable(name), let .cache(name): name
            }
        }

        var isExcludedFromBackup: Bool {
            switch self {
            case .durable: false
            case .cache: true
            }
        }
    }

    private let namespace: Namespace
    private let fileManager: FileManager

    public init(namespace: Namespace, fileManager: FileManager = .default) {
        self.namespace = namespace
        self.fileManager = fileManager
    }

    public func data(forKey key: String) throws -> Data? {
        let url = try fileURL(forKey: key)
        // 부재는 오류가 아니다(프로토콜 규약: nil = 값 부재).
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }

    public func set(_ data: Data, forKey key: String) throws {
        let url = try fileURL(forKey: key)
        try data.write(to: url, options: .atomic)
    }

    public func removeValue(forKey key: String) throws {
        let url = try fileURL(forKey: key)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    // MARK: - 경로

    private func fileURL(forKey key: String) throws -> URL {
        try directoryURL().appendingPathComponent("\(sanitized(key)).json")
    }

    /// 디렉터리는 접근 시점에 만든다(지연 생성) — init을 throwing으로 만들지 않기 위해서다.
    /// 백업 제외 속성은 디렉터리 단위로 한 번만 붙인다.
    private func directoryURL() throws -> URL {
        let support = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        var directory = support.appendingPathComponent(namespace.directoryName, isDirectory: true)
        guard !fileManager.fileExists(atPath: directory.path) else { return directory }

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        if namespace.isExcludedFromBackup {
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            // 실패해도 저장 자체는 계속한다 — 백업 제외는 최선 노력 항목이다.
            try? directory.setResourceValues(values)
        }
        return directory
    }

    /// 키가 파일명이 되므로 경로 구분자·상위 참조를 막는다. 키는 코드 상수라 충돌은
    /// 실질적으로 없지만, 파일 시스템에 닿는 값을 검증 없이 쓰지 않는다.
    private func sanitized(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "..", with: "_")
    }
}
