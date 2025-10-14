//
//  APIServiceImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Alamofire
import Foundation

private let trustManager = ServerTrustManager(evaluators: [
    "atcha.p-e.kr": DisabledTrustEvaluator()
])
private let insecureSession = Session(serverTrustManager: trustManager)

final class APIServiceImpl: APIService {
    private let session: Session

    /// 기본 초기화 - SSL 우회 세션 사용
    init(session: Session = insecureSession) {
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
