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
    @Published var checkPermissionFinished: Bool = false
    private let authorizationRequestUseCase: RequestLocationAuthorizationUseCaseImpl
    
    init(authorizationRequestUseCase: RequestLocationAuthorizationUseCaseImpl) {
        self.authorizationRequestUseCase = authorizationRequestUseCase
    }
    
    func askLocationPermission() {
        Task {
            let _ = await authorizationRequestUseCase.askLocationPermission()
        }
    }
    
    func askPushPermission() {
        Task {
            let _ = await authorizationRequestUseCase.askPushPermission()
            checkPermissionFinished = true
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
