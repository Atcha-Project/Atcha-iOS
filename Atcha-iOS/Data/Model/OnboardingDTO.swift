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
    let address: String
    let lat: Double
    let lon: Double
    let alertFrequencies: [Int]
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

struct Location: Codable {
    let name: String
    let lat: Double
    let lon: Double
    let businessCategory: String
    let address: String
    let radius: String
}

struct ReverseGeocodeLocationRequest: Codable {
    let lat: Double
    let lon: Double
}

struct ReverseGeocodeLocationResponse: Codable {
    let name: String
    let address: String
    let lat: Double
    let lon: Double
}

struct SelectedLocation {
    let name: String
    let address: String
    let lat: Double
    let lon: Double
}
