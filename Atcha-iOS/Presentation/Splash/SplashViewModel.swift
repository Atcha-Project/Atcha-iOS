//
//  SplashViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

final class SplashViewModel: BaseViewModel {
    @Published private(set) var appVersionInfo: String?
    
    private let fetchUserUseCase: FetchUserUseCase
    private let checkAppVersionUseCase: CheckAppVersionUseCase
    
    var routerHandler: ((SplashRouter) -> Void)?
    
    init(fetchUserUseCase: FetchUserUseCase,
         checkAppVersionUseCase: CheckAppVersionUseCase) {
        self.fetchUserUseCase = fetchUserUseCase
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
    
    func fetchUserInfo() {
        Task {
            do {
                let _ = try await fetchUserUseCase.excute()
            } catch {
                print("유저정보 패치 실패")
            }
        }
    }
    
    func makeInitialFlow() {
        let wrapper = UserDefaultsWrapper()
        if let legInfo: LegInfo = wrapper.object(forKey: UserDefaultsWrapper.Key.legInfo.rawValue, of: LegInfo.self),
           let address: String = wrapper.string(forKey: UserDefaultsWrapper.Key.address.rawValue) {
            routerHandler?(.alarm(info: legInfo, address: address))
            return
        }
        
        if let _ = wrapper.string(forKey: UserDefaultsWrapper.Key.providerToken.rawValue) {
            if let _ = AppDIContainer.shared.tokenStorage.accessToken {
                fetchUserInfo()
                routerHandler?(.main)
            } else {
                routerHandler?(.onboarding)
            }
        } else {
            routerHandler?(.login)
        }
    }
}
