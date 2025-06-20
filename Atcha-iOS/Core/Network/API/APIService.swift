//
//  APIService.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Alamofire

protocol APIService {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func request<T: Decodable, U: Encodable>(_ endpoint: Endpoint, body: U) async throws -> T
}
