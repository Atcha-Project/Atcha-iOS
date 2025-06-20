//
//  APIServiceImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Alamofire
import Foundation

final class APIServiceImpl: APIService {
    private let session: Session
    
    init(session: Session) {
        self.session = session
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = URL(string: NetworkConstant.baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(url, method: endpoint.method, parameters: endpoint.parameters, encoding: endpoint.encoding, headers: endpoint.headers)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let decoded):
                        continuation.resume(returning: decoded)
                    case .failure(let error):
                        if let statusCode = response.response?.statusCode {
                            continuation.resume(throwing: APIError.serverError(statusCode: statusCode))
                        } else {
                            continuation.resume(throwing: APIError.unknown(error: error))
                        }
                    }
                }
        }
    }
}

extension APIServiceImpl {
    func request<T: Decodable, U: Encodable>(
        _ endpoint: Endpoint,
        body: U
    ) async throws -> T {
        guard let url = URL(string: NetworkConstant.baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(url,
                            method: endpoint.method,
                            parameters: body.toDictionary(),
                            encoding: endpoint.encoding,
                            headers: endpoint.headers)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let decoded):
                        continuation.resume(returning: decoded)
                    case .failure(let error):
                        if let statusCode = response.response?.statusCode {
                            continuation.resume(throwing: APIError.serverError(statusCode: statusCode))
                        } else {
                            continuation.resume(throwing: APIError.unknown(error: error))
                        }
                    }
                }
        }
    }
}
