/// Base navigation-flow contract.
///
/// Memory rules every conformer must follow:
/// - Store `finishDelegate` weak; the parent outlives the child.
/// - Store any `UINavigationController` reference weak unless the coordinator
///   is the window root (AppCoordinator) and therefore owns it.
/// - Parents remove finished children in `coordinatorDidFinish`.
@MainActor
public protocol Coordinator: AnyObject {
    var childCoordinators: [any Coordinator] { get set }
    var finishDelegate: (any CoordinatorFinishDelegate)? { get set }
    func start()
}

@MainActor
public protocol CoordinatorFinishDelegate: AnyObject {
    func coordinatorDidFinish(_ coordinator: any Coordinator)
}

public extension Coordinator {
    func addChild(_ coordinator: any Coordinator) {
        childCoordinators.append(coordinator)
    }

    func removeChild(_ coordinator: any Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }

    /// Call when this flow is done: releases children and notifies the parent,
    /// which removes this coordinator in `coordinatorDidFinish`.
    func finish() {
        childCoordinators.removeAll()
        finishDelegate?.coordinatorDidFinish(self)
    }
}
