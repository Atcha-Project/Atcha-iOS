//
//  AuthTokenInfo.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/21/25.
//

import Foundation

struct AuthCheckRequest: Encodable {
    let provider: Int      // ex. 0 = 카카오
    let accessToken: String
}

struct AuthCheckResponse: Decodable {
    let exists: Bool
}
