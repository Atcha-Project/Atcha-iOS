//
//  LoginDTO.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/22/25.
//

import Foundation
struct AuthCheckRequest: Encodable {
    let provider: Int
    let accessToken: String
}

struct AuthCheckResponse: Decodable {
    let exists: Bool
}

struct LoginRequest: Encodable {
    let accessToken: String
    let provider: Int
}

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

struct LoginResponse: Decodable {
    let id: Int?
    let accessToken: String?
    let refreshToken: String?
    let latitude: Double?
    let longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case accessToken
        case refreshToken
        case latitude = "lat"
        case longitude = "lon"
    }
}
