//
//  TokenInterceptor.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation
import Alamofire

final class TokenInterceptor: RequestInterceptor, @unchecked Sendable {
    private var tokenStorage: TokenStorage
    
    private let syncQueue = DispatchQueue(label: "io.atcha.tokenInterceptor.sync")
    private var isRefreshing = false
    private var waitingCompletions: [((RetryResult) -> Void)] = []
    private let refreshSession: Session
    
    init(tokenStorage: TokenStorage, refreshSession: Session = AF) {
        self.tokenStorage = tokenStorage
        self.refreshSession = refreshSession
    }
    
    func adapt(_ urlRequest: URLRequest,
               for session: Session,
               completion: @escaping (Result<URLRequest, Error>) -> Void) {
        
        var request = urlRequest
        let path = request.url?.path ?? ""
        
        let publicPaths = [
            "/auth/check",
            "/auth/login",
            "/app/version",
            "/locations/is-service-region",
            "/api/locations/rgeo",
            "/auth/reissue"
        ]
        
        if publicPaths.contains(where: { path.hasSuffix($0) }) {
            completion(.success(request))
            return
        }
        
        if path.contains("/auth/logout") {
            if let refreshToken = tokenStorage.refreshToken {
                request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
            }
        } else {
            if let accessToken = tokenStorage.accessToken {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
        }
        
        completion(.success(request))
    }
    
    func retry(_ request: Request,
               for session: Session,
               dueTo error: Error,
               completion: @escaping (RetryResult) -> Void) {
        
        guard request.retryCount == 0 else {
            completion(.doNotRetry)
            return
        }
        
        let path = request.request?.url?.path ?? "unknown"
        
        if path.contains("/auth/reissue") {
            completion(.doNotRetry); return
        }
        
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            completion(.doNotRetry)
            return
        }
        
        let actualHeaders = request.request?.allHTTPHeaderFields ?? [:]
        
        guard let refreshToken = tokenStorage.refreshToken else {
            SessionController.shared.expireAndRouteToLogin()
            completion(.doNotRetry)
            return
        }
        
        syncQueue.async {
            if self.isRefreshing {
                self.waitingCompletions.append(completion)
                return
            }
            
            self.isRefreshing = true
            self.waitingCompletions.append(completion)
            
            self.refreshAccessToken(refreshToken: refreshToken) { [weak self] result in
                guard let self = self else { return }
                
                self.syncQueue.async {
                    let waiters = self.waitingCompletions
                    self.waitingCompletions.removeAll()
                    self.isRefreshing = false
                    
                    switch result {
                    case .success(let payload):
                        guard let p = payload else {
                            SessionController.shared.expireAndRouteToLogin()
                            waiters.forEach { $0(.doNotRetry) }
                            return
                        }
                        
                        let successBody = [
                            "newAccessToken": p.accessToken,
                            "newRefreshToken": p.refreshToken
                        ]
                        
                        DiscordWebhookManager.shared.sendErrorLog(
                            baseURL: NetworkConstant.baseURL,
                            statusCode: 200,
                            method: "GET",
                            path: "/auth/reissue",
                            responseCode: "REISSUE_SUCCESS",
                            message: "토큰 재발급에 성공하여 새로운 토큰을 수신했습니다.",
                            requestHeaders: actualHeaders,
                            requestBody: successBody, // 여기서 받은 토큰 정보를 보냅니다.
                            requestParameters: nil
                        )
                        
                        self.tokenStorage.accessToken = p.accessToken
                        self.tokenStorage.refreshToken = p.refreshToken
                        
                        waiters.forEach { $0(.retry) }
                        
                    case .failure(_):
                        SessionController.shared.expireAndRouteToLogin()
                        waiters.forEach { $0(.doNotRetry) }
                    }
                }
            }
        }
    }
    
    private func refreshAccessToken(refreshToken: String,
                                    completion: @escaping (Result<RefreshTokenResponse?, Error>) -> Void) {
        let url = "\(NetworkConstant.baseURL)/auth/reissue"
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(refreshToken)"
        ]
        
        refreshSession
            .request(url, method: .get, headers: headers)
            .responseDecodable(of: APIResponse<RefreshTokenResponse>.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    completion(.success(apiResponse.result))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
