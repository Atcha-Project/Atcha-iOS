import CoreNetwork
import Domain

public struct AppVersionRepositoryImpl: AppVersionRepository {
    private let networkClient: any NetworkClient

    public init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    // 레거시는 result를 버전 문자열 하나로 디코딩했다 — 최소 지원 버전 필드가 오면 DTO로 승격한다.
    public func latestVersion() async throws -> String {
        try await networkClient.requestEnveloped(AppVersionEndpoint(), as: String.self)
    }
}
