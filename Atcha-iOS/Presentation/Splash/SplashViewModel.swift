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
    private let tokenStorage: TokenStorage
    
    var routerHandler: ((SplashRouter) -> Void)?
    
    init(fetchUserUseCase: FetchUserUseCase,
         checkAppVersionUseCase: CheckAppVersionUseCase,
         updateAppVersionUseCase: UpdateAppVersionUseCase,
         tokenStorage: TokenStorage) {
        self.fetchUserUseCase = fetchUserUseCase
        self.checkAppVersionUseCase = checkAppVersionUseCase
        self.updateAppVersionUseCase = updateAppVersionUseCase
        self.tokenStorage = tokenStorage
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
        
        if tokenStorage.accessToken != nil {
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
