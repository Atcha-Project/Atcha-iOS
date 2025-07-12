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
    var selectedLocation: SelectedLocation?
    var onFinish: ((Bool) -> Void)?
    var routeHandler: ((OnboardingRoute) -> Void)?
    
    init(signUpUseCase: SignUpUseCase) {
        self.signUpUseCase = signUpUseCase
    }
    
    func signUp(selectedAlarms: [AlarmTimeOption]) async throws {
        guard let provider = UserDefaultsWrapper().integer(forKey: UserDefaultsWrapper.Key.provider.rawValue) else {
            print("❌ 플랫폼 정보 없음")
            return
        }
        
        guard let location = selectedLocation else {
            print("⚠️ 선택된 위치가 없습니다.")
            return
        }
        
        guard let fcmToken = AppDIContainer.shared.tokenStorage.fcmToken else {
            print("⚠️ FCM 토큰이 없습니다.")
            return
        }
        
        let request = SignUpRequest(
            provider: provider,
            userName: "",
            address: location.address,
            lat: location.lat,
            lon: location.lon,
            alertFrequencies: selectedAlarms.map { $0.rawValue },
            fcmToken: fcmToken
        )
        
        do {
            let response = try await signUpUseCase.excute(request)
            
            AppDIContainer.shared.tokenStorage.accessToken = response.accessToken
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
