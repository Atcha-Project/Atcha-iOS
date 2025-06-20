//
//  SplashViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

final class SplashViewModel: BaseViewModel {
    @Published private(set) var appVersionInfo: AppVersionInfo?
    
    private let checkAppVersionUseCase: CheckAppVersionUseCase
    
    init(checkAppVersionUseCase: CheckAppVersionUseCase) {
        self.checkAppVersionUseCase = checkAppVersionUseCase
        super.init()
    }
    
    func checkAppVersion() {
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
}
