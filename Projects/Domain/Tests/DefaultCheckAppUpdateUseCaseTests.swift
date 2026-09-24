@testable import Domain
import Testing

private struct StubAppVersionRepository: AppVersionRepository {
    let latest: String
    func latestVersion() async throws -> String { latest }
}

struct DefaultCheckAppUpdateUseCaseTests {
    @Test(arguments: [
        ("2.0.1", "2.0.0", true),
        ("2.10.0", "2.9.9", true),
        ("2.1", "2.0.9", true),
        ("2.0", "2.0.0", false),
        ("2.0.0", "2.0.1", false),
        ("garbage", "2.0.0", false),
    ])
    func isNewer_comparesNumerically(candidate: String, current: String, expected: Bool) {
        #expect(AppVersion.isNewer(candidate, than: current) == expected)
    }

    @Test
    func execute_newerOnServer_recommends() async throws {
        let sut = DefaultCheckAppUpdateUseCase(repository: StubAppVersionRepository(latest: "2.1.0"))
        #expect(try await sut.execute(currentVersion: "2.0.0") == .recommended(latest: "2.1.0"))
    }

    @Test
    func execute_sameVersion_isUpToDate() async throws {
        let sut = DefaultCheckAppUpdateUseCase(repository: StubAppVersionRepository(latest: "2.0.0"))
        #expect(try await sut.execute(currentVersion: "2.0.0") == .upToDate)
    }
}
