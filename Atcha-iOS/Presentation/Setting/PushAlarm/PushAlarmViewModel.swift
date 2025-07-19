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
    var routeHandler: ((OnboardingRoute) -> Void)?
    
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
            alertFrequencies: selectedAlarms.map { $0.rawValue },
            fcmToken: fcmToken
        )
        
        Task {
            do {
                let response = try await signUpUseCase.excute(request)
                print("response: \(response)")
                
                print("accessToken 저장 전: \(response.accessToken)")
                AppDIContainer.shared.tokenStorage.accessToken = response.accessToken
                print("저장된 accessToken: \(AppDIContainer.shared.tokenStorage.accessToken ?? "nil")")
                AppDIContainer.shared.tokenStorage.refreshToken = response.refreshToken
                
                UserDefaultsWrapper().set(response.id, forKey: UserDefaultsWrapper.Key.userId.rawValue)
                UserDefaultsWrapper().set(response.lat, forKey: UserDefaultsWrapper.Key.lat.rawValue)
                UserDefaultsWrapper().set(response.lon, forKey: UserDefaultsWrapper.Key.lon.rawValue)
                
                onFinish?(true)
            } catch {
                onFinish?(false)
            }
        }
    }
}
