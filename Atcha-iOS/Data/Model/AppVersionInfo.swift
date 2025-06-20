//
//  AppVersionInfo.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation

struct AppVersionInfo: Decodable {
    let latestVersion: String
    let minSupportedVersion: String
    let forceUpdate: Bool
}
