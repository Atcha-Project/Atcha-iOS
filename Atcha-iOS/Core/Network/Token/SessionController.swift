//
//  SessionController.swift
//  Atcha-iOS
//
//  Created by wodnd on 9/21/25.
//

import Foundation

final class SessionController {
    static let shared = SessionController()
    private init() {}

    var routeToLogin: (() -> Void)?

    private var isRouting = false

    func expireAndRouteToLogin() {
        // 중복 라우팅 방지
        if isRouting { return }
        isRouting = true

        // 로컬 세션 정리
        let storage = AppDIContainer.shared.tokenStorage
        storage.clearAccessToken()
        storage.clearRefreshToken()
        UserDefaultsWrapper.shared.removeAll()
        AppDIContainer.shared.locationStateHolder.clear()

        // 로그인 화면으로
        DispatchQueue.main.async { [weak self] in
            self?.routeToLogin?()
            self?.isRouting = false
        }
    }
}
