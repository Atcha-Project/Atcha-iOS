//
//  PermissionViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/15/25.
//

import Foundation
import CoreLocation
import UserNotifications

final class PermissionViewModel : BaseViewModel {
    @Published var checkPermissionFinished: Bool = false
    @Published var showLocationDeniedAlert: Bool = false
    @Published var showPushDeniedAlert: Bool = false

    private var streamTask: Task<Void, Never>?

    private let authorizationRequestUseCase: RequestLocationAuthorizationUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private let locationStateHolder: LocationStateHolder

    init(
        authorizationRequestUseCase: RequestLocationAuthorizationUseCase,
        streamUseCase: ObserveLocationStreamUseCase,
        locationStateHolder: LocationStateHolder
    ) {
        self.authorizationRequestUseCase = authorizationRequestUseCase
        self.streamUseCase = streamUseCase
        self.locationStateHolder = locationStateHolder
    }

    func startPermissionFlow() {
        Task {
            let status = await authorizationRequestUseCase.askLocationPermission()

            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                await requestPushThenContinue()

            case .denied, .restricted, .notDetermined:
                await MainActor.run { self.showLocationDeniedAlert = true }

            @unknown default:
                await MainActor.run { self.showLocationDeniedAlert = true }
            }
        }
    }

    /// 위치 거절 Alert 이후
    func continueToPushPermission() {
        Task {
            await requestPushThenContinue()
        }
    }

    /// 알림 거절 Alert - 닫기
    func continueAfterPushDeniedAlertDismiss() {
        Task { @MainActor in
            self.checkPermissionFinished = true
        }
    }

    /// 알림 거절 Alert - 설정 갔다가 복귀
    func continueAfterPushDeniedAlertFromSettings() {
        Task { @MainActor in
            self.checkPermissionFinished = true
        }
    }

    // MARK: - Private

    private func requestPushThenContinue() async {
        let granted = await authorizationRequestUseCase.askPushPermission()

        if !granted {
            await MainActor.run { self.showPushDeniedAlert = true }
            return
        }

        self.checkPermissionFinished = true
        requestMyLocation()
    }

    private func requestMyLocation() {
        Task {
            streamTask = Task {
                for await location in streamUseCase.startUpdate() {
                    let currentLocation = CLLocationCoordinate2D(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                    locationStateHolder.currentLocationSubject.send(currentLocation)    
                    break
                }
            }
        }
    }
}
