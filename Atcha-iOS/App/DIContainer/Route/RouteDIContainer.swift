//
//  RouteDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import Foundation

final class RouteDIContainer {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func makeDetailRouteViewModel(routeId: String?) -> DetailRouteViewModel {
        return DetailRouteViewModel(routeId: routeId)
    }
    
    func makeDetailRouteViewController(viewModel: DetailRouteViewModel) -> DetailRouteViewController {
        return DetailRouteViewController(viewModel: viewModel)
    }
}
