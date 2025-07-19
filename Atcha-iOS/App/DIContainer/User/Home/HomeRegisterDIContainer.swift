//
//  HomeRegisterDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/8/25.
//

import Foundation

final class HomeRegisterDIContainer {
    private let locationStateHolder: LocationStateHolder
    private let apiService: APIService
    
    init(apiService: APIService,
         locationStateHolder: LocationStateHolder) {
        self.apiService = apiService
        self.locationStateHolder = locationStateHolder
    }
    
    private lazy var authorizationRequestUseCase = RequestLocationAuthorizationUseCaseImpl(repository: PermissionRepositoryImpl())
    private lazy var addressRepository: AddressRepository = AddressRepositoryImpl(apiService: apiService)
    private lazy var searchAddressUseCase: SearchAddressUseCase = SearchAddressUseCaseImpl(repository: addressRepository)
    private lazy var streamUseCase: ObserveLocationStreamUseCase = ObserLocationStreamUseCaseImpl(repository: LocationStreamRepositoryImpl())
    
    func makeHomeRegisterViewModel(context: HomeRegisterContext) -> HomeRegisterViewModel {
        return HomeRegisterViewModel(context: context,
                                     searchAddressUseCase: searchAddressUseCase,
                                     streamUseCase: streamUseCase,
                                     locationStateHolder: locationStateHolder)
    }
    
    func makeHomeRegisterViewController(viewModel: HomeRegisterViewModel) -> HomeRegisterViewController {
        return HomeRegisterViewController(viewModel: viewModel)
    }
    
    func makeHomeFindViewModel() -> HomeFindViewModel {
        let viewModel = HomeFindViewModel(searchAddressUseCase: searchAddressUseCase,
                                          locationStateHolder: locationStateHolder)
        return viewModel
    }
    
    func makeHomeFindViewController(viewModel: HomeFindViewModel) -> HomeFindViewController {
        return HomeFindViewController(viewModel: viewModel)
    }
    
    func makeHomeSearchViewModel() -> SearchLocationViewModel {
        return SearchLocationViewModel(searchAddressUseCase: searchAddressUseCase,
                                       authorizationUseCase: authorizationRequestUseCase,
                                       locationStateHolder: locationStateHolder)
    }
    
    func makeHomeSearchViewController(viewModel: SearchLocationViewModel) -> SearchLocationViewController {
        return SearchLocationViewController(viewModel: viewModel)
    }
}
