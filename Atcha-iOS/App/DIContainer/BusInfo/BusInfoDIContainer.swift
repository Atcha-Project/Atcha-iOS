//
//  BusInfoDIContainer.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation
import UIKit

final class BusInfoDIContainer {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func makeBusDetailViewModel(busDetailInfo: BusDetailInfo) -> BusDetailViewModel {
        let busInfoUseCase = BusInfoUseCaseImpl(repository: BusInfoRepositoryImpl(apiService: apiService))
        return BusDetailViewModel(busInfoUseCase: busInfoUseCase, busDetailInfo: busDetailInfo)
    }

    func makeBusDetailViewController(viewModel: BusDetailViewModel) -> UIViewController {
        return BusDetailViewController(viewModel: viewModel)
    }
    
    func makeBusInfoViewModel(busDetailInfo: BusDetailInfo, busRouteInfo: BusRouteInfo) -> BusInfoViewModel {
        let busInfoUseCase = BusInfoUseCaseImpl(repository: BusInfoRepositoryImpl(apiService: apiService))
        return BusInfoViewModel(busInfoUseCase: busInfoUseCase, busDetailInfo: busDetailInfo, busRouteInfo: busRouteInfo)
    }

    func makeBusInfoViewController(viewModel: BusInfoViewModel) -> UIViewController {
        return BusInfoViewController(viewModel: viewModel)
    }
}

