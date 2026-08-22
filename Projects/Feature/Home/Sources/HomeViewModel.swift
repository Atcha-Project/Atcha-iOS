import Domain
import Foundation

// Convention: every ViewModel in the codebase is @MainActor.
@MainActor
final class HomeViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(HomeViewData)
        case failed(message: String)
    }

    /// Set by the ViewController; always invoked on the main actor.
    var onStateChange: ((State) -> Void)?

    private(set) var state: State = .idle {
        didSet { onStateChange?(state) }
    }

    private let fetchHomeUseCase: any FetchHomeUseCase
    private var loadTask: Task<Void, Never>?

    init(fetchHomeUseCase: any FetchHomeUseCase) {
        self.fetchHomeUseCase = fetchHomeUseCase
    }

    deinit {
        loadTask?.cancel()
    }

    func viewDidLoad() {
        load()
    }

    func refresh() {
        load()
    }

    private func load() {
        loadTask?.cancel()
        state = .loading
        // [weak self]: the in-flight task must not keep the ViewModel alive.
        loadTask = Task { [weak self] in
            guard let useCase = self?.fetchHomeUseCase else { return }
            do {
                let summary = try await useCase.execute()
                guard !Task.isCancelled else { return }
                self?.state = .loaded(HomeViewData(entity: summary))
            } catch {
                guard !Task.isCancelled else { return }
                self?.state = .failed(message: "홈 정보를 불러오지 못했습니다.")
            }
        }
    }
}
