//
//  PushAlarmViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import Foundation
import Combine

final class PushAlarmViewModel: BaseViewModel {
    private let signUpUseCase: SignUpUseCase
    private let locationStateHolder: LocationStateHolder
    
    var onFinish: ((Bool) -> Void)?
    var routeHandler: ((HomeRouter) -> Void)?
    
    init(signUpUseCase: SignUpUseCase,
         locationStateHolder: LocationStateHolder) {
        self.signUpUseCase = signUpUseCase
        self.locationStateHolder = locationStateHolder
    }
    
    func signUp(selectedAlarms: [AlarmTimeOption]) {
        guard let provider = UserDefaultsWrapper().integer(forKey: UserDefaultsWrapper.Key.provider.rawValue) else {
            print("❌ 플랫폼 정보 없음")
            return
        }
        
        guard let fcmToken = AppDIContainer.shared.tokenStorage.fcmToken else {
            print("⚠️ FCM 토큰이 없습니다.")
            return
        }
        
        let request = SignUpRequest(
            provider: provider,
            userName: "",
            address: locationStateHolder.address ?? "",
            lat: locationStateHolder.currentLocation?.latitude ?? 0.0,
            lon: locationStateHolder.currentLocation?.longitude ?? 0.0,
            alertFrequencies: [1] + selectedAlarms.map { $0.rawValue },
            fcmToken: fcmToken
        )
        
        // TODO: 위치 변경해야할 듯 
        UserDefaultsWrapper().set(locationStateHolder.currentLocation?.latitude ?? 0.0, forKey: UserDefaultsWrapper.Key.homeLat.rawValue)
        UserDefaultsWrapper().set(locationStateHolder.currentLocation?.longitude ?? 0.0, forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
        
        Task {
            do {
                let response = try await signUpUseCase.excute(request)
                
                AppDIContainer.shared.tokenStorage.accessToken = response.accessToken
                AppDIContainer.shared.tokenStorage.refreshToken = response.refreshToken
                
                UserDefaultsWrapper().set(response.id, forKey: UserDefaultsWrapper.Key.userId.rawValue)
                if let lat = response.lat, let lon = response.lon {
                    UserDefaultsWrapper().set(lat, forKey: UserDefaultsWrapper.Key.homeLat.rawValue)
                    UserDefaultsWrapper().set(lon, forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
                    print("✅ 회원가입 lat/lon 저장 완료: \(lat), \(lon)")
                } else {
                    print("⚠️ 회원가입 응답에 lat/lon 없음")
                }
                
                onFinish?(true)
            } catch {
                onFinish?(false)
            }
        }
    }
}
