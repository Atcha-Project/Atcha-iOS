//
//  HomeRegisterDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/8/25.
//

import Foundation

final class HomeRegisterDIContainer {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    private lazy var addressRepository: AddressRepository = AddressRepositoryImpl(apiService: apiService)
    private lazy var searchAddressUseCase: SearchAddressUseCase = SearchAddressUseCaseImpl(repository: addressRepository)
    
    func makeHomeRegisterViewModel() -> HomeRegisterViewModel {
        return HomeRegisterViewModel(searchAddressUseCase: searchAddressUseCase)
    }
    
    func makeHomeRegisterViewController() -> HomeRegisterViewController {
        return HomeRegisterViewController(viewModel: makeHomeRegisterViewModel())
    }
    
    func makeHomeFindViewModel() -> HomeFindViewModel {
        return HomeFindViewModel(searchAddressUseCase: searchAddressUseCase)
    }
    
    func makeHomeFindViewController() -> HomeFindViewController {
        return HomeFindViewController(viewModel: makeHomeFindViewModel())
    }
}
