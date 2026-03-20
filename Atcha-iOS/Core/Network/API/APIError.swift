//
//  APIError.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case decodingError
    case serverError(statusCode: Int, responseCode: String? = nil)
    case unknown(error: Error)
    case noData
}
