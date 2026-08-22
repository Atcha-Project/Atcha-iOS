@testable import CoreCoordinator
import Testing

@MainActor
private final class TestCoordinator: Coordinator {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?
    func start() {}
}

@MainActor
private final class ParentCoordinator: Coordinator, CoordinatorFinishDelegate {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?
    func start() {}

    func coordinatorDidFinish(_ coordinator: any Coordinator) {
        removeChild(coordinator)
    }
}

@MainActor
struct CoordinatorTests {
    @Test
    func finish_notifiesParentAndParentRemovesChild() {
        let parent = ParentCoordinator()
        let child = TestCoordinator()
        child.finishDelegate = parent
        parent.addChild(child)
        #expect(parent.childCoordinators.count == 1)

        child.finish()
        #expect(parent.childCoordinators.isEmpty)
    }
}
