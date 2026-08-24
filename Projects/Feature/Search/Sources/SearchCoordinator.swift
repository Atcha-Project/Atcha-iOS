import CoreCoordinator
import Domain
import SearchFeatureInterface
import UIKit

// NSObject 상속은 UINavigationControllerDelegate(NSObjectProtocol) 요구 — 이탈 경로
// (백 버튼·스와이프 백·popToRoot)를 didShow 한 지점에서 정리하기 위해서다(Phase 17).
final class SearchCoordinator: NSObject, Coordinator {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?

    // The App (window root) owns the navigation controller.
    private weak var navigationController: UINavigationController?
    private let container: SearchDIContainer
    private let initialField: SearchEntryField
    private let onRouteSelected: (LastRoute, Place) -> Void
    // didShow 정리 판정용 — pop이 끝나 이 VC가 스택에 없으면 플로우 종료다.
    private weak var searchViewController: UIViewController?
    private weak var previousNavigationDelegate: (any UINavigationControllerDelegate)?
    // 모든 이탈 경로가 didShow로 수렴한다 — finish는 1회만.
    private var isFinished = false

    init(
        navigationController: UINavigationController,
        container: SearchDIContainer,
        initialField: SearchEntryField,
        onRouteSelected: @escaping (LastRoute, Place) -> Void
    ) {
        self.navigationController = navigationController
        self.container = container
        self.initialField = initialField
        self.onRouteSelected = onRouteSelected
    }

    func start() {
        guard let navigationController else { return }
        let viewController = container.makeSearchViewController(
            initialField: initialField,
            onRouteChosen: { [weak self] route, arrival in
                self?.onRouteSelected(route, arrival)
                self?.closeFlow()
            },
            onBack: { [weak self] in
                self?.closeFlow()
            }
        )
        searchViewController = viewController
        previousNavigationDelegate = navigationController.delegate
        navigationController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    /// pop만 한다 — 코디네이터 정리는 didShow가 수행한다(이탈 경로 공통의 단일 지점).
    private func closeFlow() {
        navigationController?.popViewController(animated: true)
    }
}

extension SearchCoordinator: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        guard !isFinished else { return }
        // 검색 VC가 아직 스택에 있으면(최초 push·스와이프 취소) 플로우 진행 중이다.
        if let searchViewController,
           navigationController.viewControllers.contains(searchViewController) {
            return
        }
        isFinished = true
        navigationController.delegate = previousNavigationDelegate
        finish()
    }
}
