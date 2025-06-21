//
//  SplashDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/21/25.
//

import Foundation

final class SplashDIContainer {
    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func makeAppVersionRepository() -> AppVersionRepository {
        AppVersionRepositoryImpl(apiService: apiService)
    }

    func makeCheckAppVersionUseCase() -> CheckAppVersionUseCase {
        CheckAppVersionUseCaseImpl(repository: makeAppVersionRepository())
    }

    func makeSplashViewModel() -> SplashViewModel {
        SplashViewModel(checkAppVersionUseCase: makeCheckAppVersionUseCase())
    }
}
