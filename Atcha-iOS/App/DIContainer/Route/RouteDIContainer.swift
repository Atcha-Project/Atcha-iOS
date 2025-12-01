//
//  RouteDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import Foundation

final class RouteDIContainer {
    private let apiService: APIService
    
    private lazy var requestUseCase = RequestLocationAuthorizationUseCaseImpl(repository: PermissionRepositoryImpl())
    private lazy var streamUseCase = ObserLocationStreamUseCaseImpl(repository: LocationStreamRepositoryImpl())
    private lazy var busInfoUseCase = BusInfoUseCaseImpl(repository: BusInfoRepositoryImpl(apiService: apiService))
    private lazy var alarmUseCase = AlarmUseCaseImpl(repository: AlarmRepositoryImpl(apiService: apiService))
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func makeDetailRouteViewModel(address: String, infos: LegInfo, context: DetailRouteContext) -> DetailRouteViewModel {
        return DetailRouteViewModel(address: address,
                                    infos: infos,
                                    context: context,
                                    busInfoUseCase: busInfoUseCase,
                                    authorizationUseCase: requestUseCase,
                                    streamUseCase: streamUseCase,
                                    alarmUseCase: alarmUseCase)
    }
    
    func makeDetailRouteViewController(viewModel: DetailRouteViewModel) -> DetailRouteViewController {
        return DetailRouteViewController(viewModel: viewModel)
    }
}
