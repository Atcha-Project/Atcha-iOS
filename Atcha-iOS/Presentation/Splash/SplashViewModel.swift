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
        let wrapper = UserDefaultsWrapper.shared
        if let legInfo: LegInfo = wrapper.object(forKey: UserDefaultsWrapper.Key.legInfo.rawValue, of: LegInfo.self),
           let address: String = wrapper.string(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue) {
            
            // 앱 종료 이후, 재 실행 시 알람 재등록
            guard let time = legInfo.pathInfo.first?.departureDateTime else { return }
            AlarmManager.shared.startAlarm(after: time, title: "집에 가자", body: "집에 가자")
            
            if checkFutureTimeOver(dateString: legInfo.trafficInfo.first?.departureDateTime ?? "") == false {
                routerHandler?(.alarm(info: legInfo, address: address))
            } else {
                
                if let arrivalTime = UserDefaultsWrapper.shared.object(
                    forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue,
                    of: Date.self
                ) {
                    // 현재 시간이 arrivalTime 과거 인 경우
                    routerHandler?(.lockScreen(info: legInfo, address: address))
                    
                    // 현재 시간이 arrivalTime 미래 인 경우 (30분 이내)
                    
                    // 현재 시간이 arrivalTime 30분이 넘게 지난 경우
                }
                
                //                routerHandler?(.lockScreen(info: legInfo, address: address))
            }
            return
        }
        
        if let _ = wrapper.string(forKey: UserDefaultsWrapper.Key.providerToken.rawValue) { // 로그인만 진행한 경우
            if let _ = AppDIContainer.shared.tokenStorage.accessToken { // 토큰도 정상적으로 존재하는 경우
                fetchUserInfo()
                routerHandler?(.main)
            } else {
                routerHandler?(.onboarding)
            }
        } else {
            routerHandler?(.login)
        }
    }
    
    private func checkFutureTimeOver(dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = .current
        
        guard let inputDate = formatter.date(from: dateString) else {
            return false
        }
        
        let currentDate = Date()
        let timeInterval = inputDate.timeIntervalSince(currentDate)
        
        let isFuture = timeInterval > 0
        
        return isFuture
    }
}
