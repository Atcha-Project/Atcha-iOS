//
//  OnboardingDTO.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import Foundation

struct SignUpRequest: Codable {
    let provider: Int
    let userName: String
    let address: Int
    let lat: Double
    let lon: Double
    let alertFrequencies: Set<Int>
    let fcmToken: String
}

struct SignUpResponse: Codable {
    let id: Int
    let accessToken: String
    let refreshToken: String
    let lat: Double
    let lon: Double
}

struct SearchLocationRequest: Codable {
    let keyword: String
    let lat: Double
    let lon: Double
}

struct SearchLocationResponse: Codable {
    let result: [Location]
}

struct Location: Codable {
    let name: String
    let lat: Double
    let lon: Double
    let businessCategory: String
    let address: String
    let radius: String
}
