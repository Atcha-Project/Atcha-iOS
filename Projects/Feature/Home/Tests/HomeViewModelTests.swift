import Domain
@testable import HomeFeature
import Testing

private struct StubFetchHomeUseCase: FetchHomeUseCase {
    let summary: HomeSummary
    func execute() async throws -> HomeSummary { summary }
}

@MainActor
struct HomeViewModelTests {
    @Test
    func viewDidLoad_success_transitionsLoadingToLoaded() async {
        let summary = HomeSummary(id: "1", title: "막차까지 42분", subtitle: "지금 출발하면 여유있어요")
        let sut = HomeViewModel(fetchHomeUseCase: StubFetchHomeUseCase(summary: summary))

        var states: [HomeViewModel.State] = []
        await confirmation("reaches .loaded") { loaded in
            sut.onStateChange = { state in
                states.append(state)
                if case .loaded = state { loaded() }
            }
            sut.viewDidLoad()

            // Drain until the async load lands (stub resolves immediately).
            while !states.contains(where: { if case .loaded = $0 { true } else { false } }) {
                await Task.yield()
            }
        }

        #expect(states.first == .loading)
        #expect(states.last == .loaded(HomeViewData(entity: summary)))
    }
}
