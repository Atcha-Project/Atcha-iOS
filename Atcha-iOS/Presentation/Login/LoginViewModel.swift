//
//  LoginViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/21/25.
//

import Foundation

final class LoginViewModel: BaseViewModel {
    private let checkMemberRegisteredUseCase: CheckMemberRegisteredUseCase
    
    init(checkMemberRegisteredUseCase: CheckMemberRegisteredUseCase) {
        self.checkMemberRegisteredUseCase = checkMemberRegisteredUseCase
    }
    
    func checkMemberRegistered(provider: Int, accessToken: String) {
        Task {
            setLoading(true)
            defer { self.setLoading(false) }
            do {
                let request = AuthCheckRequest(provider: provider, accessToken: accessToken)
                let result = try await checkMemberRegisteredUseCase.execute(request)
                print(result)
                
                if result.exists {
                    
                } else {
                    
                }
            }
        }
    }
}
