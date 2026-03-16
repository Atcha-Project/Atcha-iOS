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
    private let updateAppVersionUseCase: UpdateAppVersionUseCase
    
    var routerHandler: ((SplashRouter) -> Void)?
    
    init(fetchUserUseCase: FetchUserUseCase,
         checkAppVersionUseCase: CheckAppVersionUseCase,
         updateAppVersionUseCase: UpdateAppVersionUseCase) {
        self.fetchUserUseCase = fetchUserUseCase
        self.checkAppVersionUseCase = checkAppVersionUseCase
        self.updateAppVersionUseCase = updateAppVersionUseCase
        super.init()
        
        self.checkAppVersion()
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
    
    func updateAppVersion(version: String) {
        Task {
            do {
                let _ = try await updateAppVersionUseCase.exectue(version: version)
            } catch {
                handleError(error)
            }
        }
    }
    
    func fetchUserInfo() {
        Task {
            do {
                let response = try await fetchUserUseCase.excute()
                if let lat = response?.coordinate?.latitude,
                   let lon = response?.coordinate?.longitude,
                   let id = response?.id{
                    UserDefaultsWrapper.shared.set(lat, forKey: UserDefaultsWrapper.Key.homeLat.rawValue)
                    UserDefaultsWrapper.shared.set(lon, forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
                    UserDefaultsWrapper.shared.set(id, forKey: UserDefaultsWrapper.Key.userId
                        .rawValue)
                    UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.reVisit
                        .rawValue)
                    
                    AmplitudeManager.shared.bindUser(id: String(id))
                    AmplitudeManager.shared.flush()
                }
                
                UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.isGuest.rawValue)
                
            } catch {
                print("유저정보 패치 실패")
            }
        }
    }
    
    func makeInitialFlow() {
        let wrapper = UserDefaultsWrapper.shared
        
        if let arrivalTime = wrapper.object(forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue, of: Date.self) {
            if isMoreThanSeconds(from: arrivalTime, seconds: 60 * 30) {
                // 30분이 넘게 지난 경우
                wrapper.remove(forKey: UserDefaultsWrapper.Key.legInfo.rawValue)
                wrapper.remove(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue)
                wrapper.remove(forKey: UserDefaultsWrapper.Key.startLat.rawValue)
                wrapper.remove(forKey: UserDefaultsWrapper.Key.startLon.rawValue)
                wrapper.remove(forKey: UserDefaultsWrapper.Key.startAddress.rawValue)
                wrapper.remove(forKey: UserDefaultsWrapper.Key.departureTime.rawValue)
                wrapper.remove(forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue)
                
                routerHandler?(.main)
                return
            }
        }
        
        if let legInfo: LegInfo = wrapper.object(forKey: UserDefaultsWrapper.Key.legInfo.rawValue, of: LegInfo.self),
           let address: String = wrapper.string(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue) {
            routerHandler?(.alarm(info: legInfo, address: address))
            return
        }
        
        if AppDIContainer.shared.tokenStorage.accessToken != nil {
            // 1. 토큰이 있는 경우 (로그인 유저) -> 유저정보 받고 메인으로!
            fetchUserInfo()
            routerHandler?(.main)
        } else {
            // 2. 토큰이 없는 경우 (신규 유저 or 로그아웃/탈퇴 유저)
            let hasSeenIntro = wrapper.bool(forKey: UserDefaultsWrapper.Key.hasSeenIntro.rawValue) ?? false
            
            if hasSeenIntro {
                // 이미 인트로를 보고 넘긴 적이 있다면 (그냥 게스트 유저) -> 바로 메인으로!
                routerHandler?(.main)
            } else {
                // 설치 후 처음 켰거나, 탈퇴(초기화) 후 처음 킨 경우 -> 인트로 화면으로!
                routerHandler?(.intro)
            }
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
    
    private func isMoreThanSeconds(from date: Date, seconds: Int) -> Bool {
        let now = Date()
        let diff = now.timeIntervalSince(date) // 초 단위 차이
        return diff >= Double(seconds)
    }
    
    private func isMoreThanSeconds(from dateString: String, seconds: Int) -> Bool {
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

// 막차를 등록한 경우
//        if let legInfo: LegInfo = wrapper.object(forKey: UserDefaultsWrapper.Key.legInfo.rawValue, of: LegInfo.self),
//           let address: String = wrapper.string(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue) {
//            guard let time = legInfo.pathInfo.first?.departureDateTime else { return } // 막차를 타기위해 출발해야 하는 시간
////            AlarmManager.shared.startAlarm(after: time, title: "눌러서 출발 알람 끄기", body: "자리에서 일어나야 할 시간이에요!")
//
//            if checkFutureTimeOver(dateString: time) {
//                // 현재 시간 > 알람 시간 -> 알람 화면
//                routerHandler?(.alarm(info: legInfo, address: address))
//            } else {
//                // 현재 시간 < 알림 시간
//
//                // 만약에 내가 실시간 조회 -> 타이머 시간이 존재하면 !!
//                if let _ = wrapper.integer(forKey: UserDefaultsWrapper.Key.trainRealTime.rawValue) {
//                    routerHandler?(.alarm(info: legInfo, address: address))
//                    // TODO: 상세경로 화면으로 이동
//                } else {
//
//                    if let arrivalTime = wrapper.object(forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue, of: Date.self) {
//                        if isMoreThanSeconds(from: arrivalTime, seconds: 60 * 30) { // 30분이 넘게 지난 경우
//                            routerHandler?(.main)
//                        } else {
//                            routerHandler?(.finishTime(info: legInfo, address: address))
//                        }
//                        return
//                    }
//
//                    // 현재 시간 - 알람 시간 2분 이내에 진입 한 경우 (time이랑 Date() 차이가 2분)
//                    if isMoreThanSeconds(from: time, seconds: 120) {
////                        routerHandler?(.main) // 진입 이후, 알람 팝업
//                        routerHandler?(.alarm(info: legInfo, address: address))
//                    } else {
//                        routerHandler?(.lockScreen(info: legInfo, address: address)) // 2분 이내에 재 진입, 잠금화면
//                    }
//                }
//            }
//            return
//        }
