//
//  UserDIConatiner.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/21/25.
//

import Foundation

final class UserDIContainer {
    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func makeUserRepository() -> UserRepository {
        UserRepositoryImpl(apiService: apiService)
    }

    func makeFetchUserUseCase() -> FetchUserUseCase {
        FetchUserUseCaseImpl(repositoy: makeUserRepository())
    }
}
