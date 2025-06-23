//
//  LoginResult.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/23/25.
//

import Foundation

enum LoginResult {
    case registered(AuthCheckResponse)
    case notRegistered
    case loginSuccess(TokenResponse)
    case loginFailed(Error)
    case logoutSuccess
    case signUpSuccess
    case withdrawalSuccess
}
