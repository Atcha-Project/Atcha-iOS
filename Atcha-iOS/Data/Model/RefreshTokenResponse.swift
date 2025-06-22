//
//  RefreshTokenResponse.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation

struct RefreshTokenResponse: Decodable {
    let id: String
    let accessToken: String
    let refreshToken: String
}
