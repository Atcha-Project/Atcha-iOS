//
//  SplashViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

final class SplashViewModel {
    @Published var user: User?
    
    private let useCase: UserUseCase

    init(useCase: UserUseCase) {
        self.useCase = useCase
    }
    
    func fetchUser() async throws {
        user = try await useCase.fetchUser()
    }
}
