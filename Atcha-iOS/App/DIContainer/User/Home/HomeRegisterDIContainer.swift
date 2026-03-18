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
    private let tokenStorage: TokenStorage
    
    init(apiService: APIService,
         locationStateHolder: LocationStateHolder,
         tokenStorage: TokenStorage) {
        self.apiService = apiService
        self.locationStateHolder = locationStateHolder
        self.tokenStorage = tokenStorage
    }
    
    private lazy var authorizationRequestUseCase = RequestLocationAuthorizationUseCaseImpl(repository: PermissionRepositoryImpl())
    private lazy var addressRepository: AddressRepository = AddressRepositoryImpl(apiService: apiService)
    private lazy var userRepository: UserRepository = UserRepositoryImpl(apiService: apiService)
    private lazy var searchAddressUseCase: SearchAddressUseCase = SearchAddressUseCaseImpl(repository: addressRepository)
    private lazy var homePatchUseCase: HomePatchUseCase = HomePatchUseCaseImpl(repository: userRepository)
    private lazy var streamUseCase: ObserveLocationStreamUseCase = ObserLocationStreamUseCaseImpl(repository: LocationStreamRepositoryImpl())
    private lazy var signUpUseCase: SignUpUseCase = SignUpUseCaseImpl(repository: userRepository)
    
    func makeHomeRegisterViewModel(context: HomeRegisterContext) -> HomeRegisterViewModel {
        return HomeRegisterViewModel(context: context,
                                     requestUseCase: authorizationRequestUseCase,
                                     searchAddressUseCase: searchAddressUseCase,
                                     streamUseCase: streamUseCase,
                                     locationStateHolder: locationStateHolder)
    }
    
    func makeHomeRegisterViewController(viewModel: HomeRegisterViewModel) -> HomeRegisterViewController {
        return HomeRegisterViewController(viewModel: viewModel)
    }
    
    func makeHomeFindViewModel(context: HomeRegisterContext) -> HomeFindViewModel {
        let viewModel = HomeFindViewModel(context: context,
                                          searchAddressUseCase: searchAddressUseCase,
                                          homePatchUseCase: homePatchUseCase,
                                          locationStateHolder: locationStateHolder, streamUseCase: streamUseCase, signUpUseCase: signUpUseCase,
                                          tokenStorage: tokenStorage)
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
