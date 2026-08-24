import CoreCoordinator
import Domain
@testable import SearchFeature
import SearchFeatureInterface
import Testing
import UIKit

// 코디네이터 조립용 최소 스텁 — Tests/Example 중복은 의도된 트레이드오프(기존 규약).
private struct StubSearchPlacesUseCase: SearchPlacesUseCase {
    func execute(keyword: String, near coordinate: Coordinate?) async throws -> [Place] { [] }
}

private struct StubSearchLastRoutesUseCase: SearchLastRoutesUseCase {
    func execute(start: Coordinate, end: Coordinate) async throws -> LastRouteSearchResult {
        .noRoute
    }
}

private struct StubRecentSearchesUseCase: RecentSearchesUseCase {
    func fetch() async throws -> [Place] { [] }
    func save(_ place: Place) async throws {}
    func remove(_ place: Place) async throws {}
}

@MainActor
private final class FinishRecorder: CoordinatorFinishDelegate {
    private(set) var finishedCount = 0
    func coordinatorDidFinish(_ coordinator: any Coordinator) { finishedCount += 1 }
}

/// 이전 delegate 복원 검증용 더미.
private final class PriorNavigationDelegate: NSObject, UINavigationControllerDelegate {}

@MainActor
private func makeCoordinator(navigationController: UINavigationController) -> SearchCoordinator {
    SearchCoordinator(
        navigationController: navigationController,
        container: SearchDIContainer(
            searchPlacesUseCase: StubSearchPlacesUseCase(),
            searchLastRoutesUseCase: StubSearchLastRoutesUseCase(),
            recentSearchesUseCase: StubRecentSearchesUseCase()
        ),
        initialField: .departure,
        onRouteSelected: { _, _ in }
    )
}

/// 이탈 경로(백 버튼·스와이프 백·popToRoot) 공통의 didShow 정리(Phase 17) —
/// 실제 전환 없이 didShow를 직접 호출해 판정 로직을 검증한다.
@MainActor
struct SearchCoordinatorTests {
    @Test
    func start_installsSelfAsNavigationDelegate() {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let prior = PriorNavigationDelegate()
        navigationController.delegate = prior
        let sut = makeCoordinator(navigationController: navigationController)

        sut.start()

        #expect(navigationController.delegate === sut)
        #expect(navigationController.viewControllers.count == 2)
    }

    @Test
    func didShow_whileSearchStillOnStack_doesNotFinish() {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let sut = makeCoordinator(navigationController: navigationController)
        let recorder = FinishRecorder()
        sut.finishDelegate = recorder
        sut.start()

        // 최초 push의 didShow — 검색 VC가 스택에 있으므로 플로우 진행 중이다.
        sut.navigationController(
            navigationController,
            didShow: navigationController.viewControllers[1],
            animated: false
        )

        #expect(recorder.finishedCount == 0)
        #expect(navigationController.delegate === sut)
    }

    @Test
    func didShow_afterPop_finishesOnceAndRestoresDelegate() {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let prior = PriorNavigationDelegate()
        navigationController.delegate = prior
        let sut = makeCoordinator(navigationController: navigationController)
        let recorder = FinishRecorder()
        sut.finishDelegate = recorder
        sut.start()

        // pop 결과 시뮬레이션 — 백 버튼·스와이프 백·popToRoot 전부 같은 스택 상태로 끝난다.
        let root = navigationController.viewControllers[0]
        navigationController.viewControllers = [root]
        sut.navigationController(navigationController, didShow: root, animated: false)

        #expect(recorder.finishedCount == 1)
        #expect(navigationController.delegate === prior)

        // 중복 didShow는 no-op — finish는 1회 가드.
        sut.navigationController(navigationController, didShow: root, animated: false)
        #expect(recorder.finishedCount == 1)
    }
}
