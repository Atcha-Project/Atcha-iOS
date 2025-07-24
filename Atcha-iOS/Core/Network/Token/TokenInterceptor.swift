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
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 400 else {
            completion(.doNotRetry)
            return
        }
        
        guard let refreshToken = tokenStorage.refreshToken else {
            completion(.doNotRetry)
            return
        }
        
        refreshAccessToken(refreshToken: refreshToken) { [weak self] result in
            switch result {
            case .success(let newAccessToken):
                self?.tokenStorage.accessToken = newAccessToken
                completion(.retry)
            case .failure:
                completion(.doNotRetry)
            }
        }
    }
    
    private func refreshAccessToken(refreshToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = "\(NetworkConstant.baseURL)/auth/reissue"
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(refreshToken)"
        ]
        
        AF.request(
            url,
            method: .get,
            headers: headers
        )
        .validate()
        .responseDecodable(of: RefreshTokenResponse.self) { response in
            switch response.result {
            case .success(let refreshResponse):
                completion(.success(refreshResponse.accessToken))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
