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
        
        // 막차를 등록한 경우
        if let legInfo: LegInfo = wrapper.object(forKey: UserDefaultsWrapper.Key.legInfo.rawValue, of: LegInfo.self),
           let address: String = wrapper.string(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue) {
            guard let time = legInfo.pathInfo.first?.departureDateTime else { return } // 막차를 타기위해 출발해야 하는 시간
            AlarmManager.shared.startAlarm(after: time, title: "눌러서 출발 알람 끄기", body: "자리에서 일언야 할 시간이에요!")
            
            if checkFutureTimeOver(dateString: time) {
                // 현재 시간 > 알람 시간 -> 알람 화면
                routerHandler?(.alarm(info: legInfo, address: address))
            } else {
                // 현재 시간 < 알림 시간
                
                // 만약에 내가 실시간 조회 -> 타이머 시간이 존재하면 !!
                if let _ = wrapper.integer(forKey: UserDefaultsWrapper.Key.trainRealTime.rawValue) {
                    routerHandler?(.realTime(info: legInfo, address: address))
                } else {
                    
                    if let _ = wrapper.object(forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue, of: Date.self) {
                        routerHandler?(.finishTime(info: legInfo, address: address))
                        return
                    }
                    
                    // 현재 시간 - 알람 시간 2분 이내에 진입 한 경우 (time이랑 Date() 차이가 2분)
                    if isMoreThanTwoMinutes(from: time) {
                        routerHandler?(.main) // 진입 이후, 알람 팝업
                    } else {
                        routerHandler?(.lockScreen(info: legInfo, address: address)) // 2분 이내에 재 진입, 잠금화면
                    }
                }
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
    
    private func isMoreThanTwoMinutes(from dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = .current
        
        guard let date = formatter.date(from: dateString) else {
            print("❌ 잘못된 날짜 형식: \(dateString)")
            return false
        }
        
        let now = Date()
        let diff = now.timeIntervalSince(date) // 초 단위 차이
        
        return diff >= 120 // 120초 = 2분
    }
}
