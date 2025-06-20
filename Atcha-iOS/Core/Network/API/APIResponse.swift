//
//  APIResponse.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation

struct APIEmptyResponse: Decodable {}

struct APIResponse<T: Decodable>: Decodable {
    let responseCode: String
    let result: T
}
