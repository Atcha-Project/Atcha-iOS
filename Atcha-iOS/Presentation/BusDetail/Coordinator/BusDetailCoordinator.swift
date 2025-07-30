//
//  BusDetailCoordinator.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation
import UIKit
import Combine

final class BusDetailCoordinator {
    var navigationController: UINavigationController
    private var cancellables = Set<AnyCancellable>()
    private let diContainer: BusInfoDIContainer
    
    init(navigationController: UINavigationController,
         diContainer: BusInfoDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }
    
    func start(busDetailInfo: BusDetailInfo) {
        let viewModel = diContainer.makeBusDetailViewModel(busDetailInfo: busDetailInfo)
        viewModel.onInfoTap = { [weak self, weak viewModel] in
            guard let self = self, let viewModel = viewModel else { return }
            print("터치됨, self:", self)
            self.showBusInfo(busDetailInfo: busDetailInfo,
                             busRouteInfo: viewModel.busRouteInfo)
        }
        let viewController = diContainer.makeBusDetailViewController(viewModel: viewModel)
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showBusInfo(busDetailInfo: BusDetailInfo, busRouteInfo: BusRouteInfo) {
        let viewModel = diContainer.makeBusInfoViewModel(busDetailInfo: busDetailInfo, busRouteInfo: busRouteInfo)
        let viewController = diContainer.makeBusInfoViewController(viewModel: viewModel)
        
        navigationController.pushViewController(viewController, animated: true)
    }
}

