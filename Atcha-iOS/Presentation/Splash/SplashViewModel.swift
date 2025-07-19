//
//  SplashViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

final class SplashViewModel: BaseViewModel {
    @Published private(set) var appVersionInfo: String?
    
    private let checkAppVersionUseCase: CheckAppVersionUseCase
    
    var routerHandler: ((SplashRouter) -> Void)?
    
    init(checkAppVersionUseCase: CheckAppVersionUseCase) {
        self.checkAppVersionUseCase = checkAppVersionUseCase
        super.init()
    }
    
    func checkAppVersion() {
        print(#function)
        Task {
            setLoading(true)
            defer { self.setLoading(false) }
            do {
                let versionInfo = try await checkAppVersionUseCase.execute()
                appVersionInfo = versionInfo
            } catch {
                handleError(error)
            }
        }
    }
    
    func checkUserStatus() {
        routerHandler?(.login)
    }
}
