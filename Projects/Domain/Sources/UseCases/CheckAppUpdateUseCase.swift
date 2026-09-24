import Foundation

public enum AppUpdateStatus: Sendable, Equatable {
    case upToDate
    /// 스토어에 더 새 버전이 있다 — 권장 팝업("업데이트 / 나중에").
    case recommended(latest: String)
}

public protocol CheckAppUpdateUseCase: Sendable {
    func execute(currentVersion: String) async throws -> AppUpdateStatus
}

public struct DefaultCheckAppUpdateUseCase: CheckAppUpdateUseCase {
    private let repository: any AppVersionRepository

    public init(repository: any AppVersionRepository) {
        self.repository = repository
    }

    // 강제 업데이트는 서버가 최소 지원 버전을 주기 전까지 판정할 근거가 없다 — 권장만 낸다.
    public func execute(currentVersion: String) async throws -> AppUpdateStatus {
        let latest = try await repository.latestVersion()
        return AppVersion.isNewer(latest, than: currentVersion)
            ? .recommended(latest: latest)
            : .upToDate
    }
}

enum AppVersion {
    /// 점 구분 숫자 비교 — "2.10" > "2.9", 자릿수 차이는 0으로 채운다.
    /// 숫자가 아닌 조각(베타 접미사 등)은 0으로 본다: 잘못된 서버 값이 팝업을 띄우지 않는 쪽으로 기운다.
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let lhs = components(candidate)
        let rhs = components(current)
        for index in 0..<max(lhs.count, rhs.count) {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left != right { return left > right }
        }
        return false
    }

    private static func components(_ version: String) -> [Int] {
        version.trimmingCharacters(in: .whitespaces)
            .split(separator: ".")
            .map { Int($0) ?? 0 }
    }
}
