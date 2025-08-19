//
//  CourseSearchRequest.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/17/25.
//

import Foundation

struct CourseSearchRequest: Codable {
    let startLat: String
    let startLon: String
    let endLat: String
    let endLon: String
}
