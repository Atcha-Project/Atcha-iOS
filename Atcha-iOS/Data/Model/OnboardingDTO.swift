//
//  OnboardingDTO.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import Foundation

struct SignUpRequest: Codable {
    let provider: Int
    let userName: String?
    let address: String
    let lat: Double
    let lon: Double
    let alertFrequencies: [Int]
    let fcmToken: String
}

struct SignUpResponse: Codable {
    let id: Int?
    let accessToken: String?
    let refreshToken: String?
    let lat: Double?
    let lon: Double?
}

struct ReverseGeocodeLocationRequest: Codable {
    let lat: Double
    let lon: Double
}

struct SelectedLocation {
    let name: String
    let address: String
    let lat: Double
    let lon: Double
}

