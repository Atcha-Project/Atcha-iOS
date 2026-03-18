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

final class APIServiceImpl: APIService, @unchecked Sendable {
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
                            self.handleFailure(response: response, endpoint: endpoint, continuation: continuation)
                        }
                    case .failure(let error):
                        self.handleFailure(response: response, endpoint: endpoint, continuation: continuation)
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
                        self.handleFailure(response: response, endpoint: endpoint, requestBody: body.toDictionary(), continuation: continuation)
                    }
                    
                case .failure(let error):
                    self.handleFailure(response: response, endpoint: endpoint, requestBody: body.toDictionary(), continuation: continuation)
                }
            }
        }
    }
}

extension APIServiceImpl {
    private func handleFailure<T>(
        response: DataResponse<APIResponse<T>, AFError>,
        endpoint: Endpoint,
        requestBody: [String: Any]? = nil,
        continuation: CheckedContinuation<T, Error>
    ) {
        let statusCode = response.response?.statusCode ?? -1
        let method = endpoint.method.rawValue.uppercased()
        let path = endpoint.path
        let requestHeaders = endpoint.headers?.dictionary ?? [:]

        var responseCode = "UNKNOWN"
        var serverMessage = "(메시지 없음)"
        var serverPath = path
        
        if let data = response.data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            responseCode = json["responseCode"] as? String ?? "UNKNOWN"
            serverMessage = json["message"] as? String ?? "(메시지 없음)"
            serverPath = json["path"] as? String ?? path
        }
        
        DiscordWebhookManager.shared.sendErrorLog(
            statusCode: statusCode,
            method: method,
            path: serverPath,
            responseCode: responseCode,
            message: serverMessage,
            requestHeaders: requestHeaders,
            requestBody: requestBody,              // POST/PUT body
            requestParameters: endpoint.parameters // GET query params
        )
        
        let apiError = APIError.serverError(statusCode: statusCode)
        NotificationCenter.default.post(name: .apiErrorOccurred, object: apiError)
        continuation.resume(throwing: apiError)
    }
}
