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
    
    init(tokenStorage: TokenStorage) {
        self.tokenStorage = tokenStorage
    }
    
    func adapt(_ urlRequest: URLRequest,
               for session: Session,
               completion: @escaping (Result<URLRequest, Error>) -> Void) {
        
        var request = urlRequest
        let path = request.url?.path ?? ""
        
        if request.value(forHTTPHeaderField: "Authorization") != nil {
            completion(.success(request)); return
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
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            completion(.doNotRetry)
            return
        }
        
        guard let refreshToken = tokenStorage.refreshToken else {
            completion(.doNotRetry)
            return
        }
        
        refreshAccessToken(refreshToken: refreshToken) { [weak self] result in
            switch result {
            case .success(let payload):
                guard let p = payload else {
                    completion(.doNotRetry)
                    return
                }
                self?.tokenStorage.accessToken = p.accessToken
                self?.tokenStorage.refreshToken = p.refreshToken
                completion(.retry)
                
            case .failure:
                SessionController.shared.expireAndRouteToLogin()
                completion(.doNotRetry)
            }
        }
    }
    
    private func refreshAccessToken(refreshToken: String,
                                    completion: @escaping (Result<RefreshTokenResponse?, Error>) -> Void) {
        let url = "https://atcha.p-e.kr/api/auth/reissue"
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(refreshToken)"
        ]
        
        AF.request(
            url,
            method: .get,
            headers: headers
        )
        //        .validate()
        .responseDecodable(of: APIResponse<RefreshTokenResponse>.self) { response in
            switch response.result {
            case .success(let refreshResponse):
                print("refreshResponse : \(refreshResponse)")
                completion(.success(refreshResponse.result))
            case .failure(let error):
                print("error123 : ", error.localizedDescription)
            }
        }
    }
}
