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
                .responseDecodable(of: APIResponse<T>.self) { response in
                    if let statusCode = response.response?.statusCode,
                       (200...299).contains(statusCode),
                       T.self == APIEmptyResponse.self {
                        continuation.resume(returning: APIEmptyResponse() as! T)
                        return
                    }
                    
                    switch response.result {
                    case .success(let apiResponse):
                        if apiResponse.responseCode == "SUCCESS" {
                            /// result가 존재하면 그대로 반환
                            if let result = apiResponse.result {
                                continuation.resume(returning: result)
                            
                            /// result는 없지만 기대 타입이 APIEmptyResponse인 경우, 빈 응답 객체 반환
                            } else if T.self == APIEmptyResponse.self {
                                continuation.resume(returning: APIEmptyResponse() as! T)
                                
                            ///  result도 없고, 기대 타입이 빈 응답도 아님 → 예외 처리
                            } else {
                                continuation.resume(throwing: APIError.noData)
                            }
                        } else {
                            continuation.resume(throwing: APIError.serverError(statusCode: response.response?.statusCode ?? -1))
                        }
                    case .failure(let error):
                        continuation.resume(throwing: APIError.unknown(error: error))
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
            session.request(
                url,
                method: endpoint.method,
                parameters: body.toDictionary(),
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
            .validate()
            .responseDecodable(of: APIResponse<T>.self) { response in
                if let statusCode = response.response?.statusCode,
                   (200...299).contains(statusCode),
                   T.self == APIEmptyResponse.self {
                    continuation.resume(returning: APIEmptyResponse() as! T)
                    return
                }
                
                switch response.result {
                case .success(let apiResponse):
                    if apiResponse.responseCode == "SUCCESS" {
                        if let result = apiResponse.result {
                            continuation.resume(returning: result)
                        } else if T.self == APIEmptyResponse.self {
                            continuation.resume(returning: APIEmptyResponse() as! T)
                        } else {
                            continuation.resume(throwing: APIError.noData)
                        }
                    } else {
                        continuation.resume(throwing: APIError.serverError(statusCode: response.response?.statusCode ?? -1))
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: APIError.unknown(error: error))
                }
            }
        }
    }
}
