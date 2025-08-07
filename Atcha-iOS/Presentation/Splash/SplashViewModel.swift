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
           let address: String = wrapper.string(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue) {
            
            // 앱 종료 이후, 재 실행 시 알람 재등록
            guard let time = legInfo.pathInfo.first?.departureDateTime else { return }
            AlarmManager.shared.startAlarm(after: time, title: "집에 가자", body: "집에 가자")
            
            if checkFutureTimeOver(dateString: legInfo.trafficInfo.first?.departureDateTime ?? "")?.0 == true {
                routerHandler?(.alarm(info: legInfo, address: address))
            } else {
                routerHandler?(.lockScreen(info: legInfo, address: address))
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
    
    private func checkFutureTimeOver(dateString: String) -> (isFuture: Bool, secondsUntil: TimeInterval)? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = .current
        
        guard let inputDate = formatter.date(from: dateString) else {
            print("날짜 파싱 실패")
            return nil
        }
        
        let currentDate = Date()
        let timeInterval = inputDate.timeIntervalSince(currentDate)
        
        let isFuture = timeInterval > 0
        let secondsUntil = max(0, timeInterval) // 미래가 아니면 0초로 처리
        
        return (isFuture, secondsUntil)
    }
}
