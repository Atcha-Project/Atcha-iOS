//
//  PushAlarmViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import Foundation

final class PushAlarmViewModel: BaseViewModel {
    private let onboardingUseCase: OnboardingUseCase
    var selectedLocation: SelectedLocation?
    var onFinish: ((Bool) -> Void)?
    
    init(onboardingUseCase: OnboardingUseCase) {
        self.onboardingUseCase = onboardingUseCase
    }
    
    func signUp(provider: Int, selectedAlarms: [String]) async throws {
        let alarmTimeMapping: [String: Int] = [
            "1분 전": 1,
            "5분 전": 5,
            "10분 전": 10,
            "20분 전": 20,
            "30분 전": 30,
            "1시간 전": 60
        ]
        
        var alertFrequencies: [Int] = [1]
        for alarm in selectedAlarms {
            if alarm != "1분 전", let value = alarmTimeMapping[alarm] {
                alertFrequencies.append(value)
            }
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
            alertFrequencies: alertFrequencies,
            fcmToken: fcmToken
        )
        
        do {
            let response = try await onboardingUseCase.signUp(request)
            
            AppDIContainer.shared.tokenStorage.accessToken = response.accessToken
            AppDIContainer.shared.tokenStorage.refreshToken = response.refreshToken
            
            UserDefaultsWrapper().set(response.id, forKey: UserDefaultsWrapper.Key.userId.rawValue)
            UserDefaultsWrapper().set(response.lat, forKey: UserDefaultsWrapper.Key.lat.rawValue)
            UserDefaultsWrapper().set(response.lon, forKey: UserDefaultsWrapper.Key.lon.rawValue)
            
            onFinish?(true)
        } catch {
            print("회원가입 실패: \(error)")
            onFinish?(false)
        }        
    }
}
