@testable import Domain
import Testing

private struct StubHomeRepository: HomeRepository {
    let summary: HomeSummary
    func fetchHomeSummary() async throws -> HomeSummary { summary }
}

struct DefaultFetchHomeUseCaseTests {
    @Test
    func execute_returnsRepositoryEntity() async throws {
        let expected = HomeSummary(id: "1", title: "t", subtitle: "s")
        let sut = DefaultFetchHomeUseCase(repository: StubHomeRepository(summary: expected))
        let result = try await sut.execute()
        #expect(result == expected)
    }
}
