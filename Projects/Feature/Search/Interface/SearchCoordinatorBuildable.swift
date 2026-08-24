import CoreCoordinator
import Domain
import UIKit

/// 검색 진입 시 활성화할 슬롯 — 홈의 어느 필드를 탭했는지가 그대로 넘어온다(Phase 17).
public enum SearchEntryField: Sendable, Equatable {
    case departure
    case arrival
}

/// Entry point other modules use to start the Search flow.
/// The concrete builder is the feature's DIContainer; wiring happens at the
/// App composition root.
@MainActor
public protocol SearchCoordinatorBuildable {
    /// onRouteSelected의 Place는 확정된 도착지 — 홈 도착지 필드가 이 이름과 정합한다(Phase 17).
    func makeSearchCoordinator(
        navigationController: UINavigationController,
        initialField: SearchEntryField,
        onRouteSelected: @escaping (LastRoute, Place) -> Void
    ) -> any Coordinator
}
