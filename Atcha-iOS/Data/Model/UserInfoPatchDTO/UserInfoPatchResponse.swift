//
//  UserInfoPatchResponse.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/6/25.
//

import Foundation

struct UserInfoPatchResponse: Codable {
    let id: Int?
    let providerId: String?
    let address: String?
    let lat: Double?
    let lon: Double?
}
