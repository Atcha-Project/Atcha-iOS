//
//  PushAlarmViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import Foundation
import Combine

enum PushAlarmContext {
    case myPage
}

final class PushAlarmViewModel: BaseViewModel {
    @Published private(set) var context: PushAlarmContext
    private let signUpUseCase: SignUpUseCase
    private let pushAlarmPatchUseCase: PushAlarmPatchUseCase
    private let locationStateHolder: LocationStateHolder
    
    var onFinish: ((Bool) -> Void)?
    var routeHandler: ((HomeRouter) -> Void)?
    
    init(context: PushAlarmContext,
         signUpUseCase: SignUpUseCase,
         pushAlarmPatchUseCase: PushAlarmPatchUseCase,
         locationStateHolder: LocationStateHolder) {
        self.context = context
        self.signUpUseCase = signUpUseCase
        self.pushAlarmPatchUseCase = pushAlarmPatchUseCase
        self.locationStateHolder = locationStateHolder
    }
    
    func signUp() {
        guard let provider = UserDefaultsWrapper.shared.integer(forKey: UserDefaultsWrapper.Key.provider.rawValue) else {
            print("플랫폼 정보 없음")
            return
        }
        
        guard let fcmToken = AppDIContainer.shared.tokenStorage.fcmToken else {
            print("FCM 토큰이 없습니다.")
            return
        }
        
        let request = SignUpRequest(
            provider: provider,
            userName: "",
            address: locationStateHolder.address ?? "",
            lat: locationStateHolder.currentLocation?.latitude ?? 0.0,
            lon: locationStateHolder.currentLocation?.longitude ?? 0.0,
            alertFrequencies: [1, 10],
            fcmToken: fcmToken
        )
        
        // TODO: 위치 변경해야할 듯
        UserDefaultsWrapper.shared.set(locationStateHolder.currentLocation?.latitude ?? 0.0, forKey: UserDefaultsWrapper.Key.homeLat.rawValue)
        UserDefaultsWrapper.shared.set(locationStateHolder.currentLocation?.longitude ?? 0.0, forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
        
        Task {
            do {
                let response = try await signUpUseCase.excute(request)
                
                AppDIContainer.shared.tokenStorage.accessToken = response.accessToken
                AppDIContainer.shared.tokenStorage.refreshToken = response.refreshToken
                
                UserDefaultsWrapper.shared.set(response.id, forKey: UserDefaultsWrapper.Key.userId.rawValue)
                if let lat = response.lat, let lon = response.lon, let id = response.id {
                    UserDefaultsWrapper.shared.set(lat, forKey: UserDefaultsWrapper.Key.homeLat.rawValue)
                    UserDefaultsWrapper.shared.set(lon, forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
                    UserDefaultsWrapper.shared.set(id, forKey: UserDefaultsWrapper.Key.userId
                        .rawValue)
                    UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.reVisit
                        .rawValue)
                    
                    let dwellSeconds = AmplitudeManager.shared.timerEndSeconds("signup_dwell")
                    AmplitudeManager.shared.track(
                        .signup,
                        props(
                            AmplitudeProperty.dwellTime(seconds: dwellSeconds)
                        )
                    )
                    print("회원가입 lat/lon 저장 완료: \(lat), \(lon)")
                } else {
                    print("회원가입 응답에 lat/lon 없음")
                }
                
                onFinish?(true)
            } catch {
                onFinish?(false)
            }
        }
    }
    
    
//    func pushAlarmPatch(selectedAlarms: [AlarmTimeOption]) async throws {
//        let request = PushAlarmPatchRequest(alertFrequencies: selectedAlarms.map { $0.rawValue })
//        let response = try await pushAlarmPatchUseCase.pushAlarmPatch(request)
//    }
}
