//
//  PermissionViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/15/25.
//

import Foundation
import UIKit
import CoreLocation

final class PermissionViewModel: BaseViewModel {
    @Published var deniedAlert: PermissionType?
    private let authorizationRequestUseCase: RequestLocationAuthorizationUseCaseImpl
    
    init(authorizationRequestUseCase: RequestLocationAuthorizationUseCaseImpl) {
        self.authorizationRequestUseCase = authorizationRequestUseCase
    }
    
    func askLocationPermission() {
        Task {
            let status = await authorizationRequestUseCase.askLocationPermission()
            print("status : \(status)")
            handleLocationStatus(status)
        }
    }
    
    func askPushPermission() {
        Task {
            let granted = await authorizationRequestUseCase.askPushPermission()
        }
    }
    
    private func handleLocationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("✅ 성공")
            // 이후 로직 실행
        default:
            print("❌ 실패")
            // 실패 대응
        }
    }
    
    func checkPushPermission(granted: Bool) {
        if granted {
            print("화면닫기")
        } else {
            deniedAlert = .push
        }
    }
}


enum AlertFactory {
    
    static func makeSettingsAlert(
        title: String? = nil,
        message: String,
        cancelTitle: String = "취소",
        confirmTitle: String = "설정 하러 가기",
        onConfirmTapped: @escaping () -> Void = {}
    ) -> UIAlertController {
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
        let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { _ in
            onConfirmTapped()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        
        return alert
    }
}
