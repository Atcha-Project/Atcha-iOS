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

        if let token = tokenStorage.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
        AF.request(url, method: .post, parameters: ["refresh_token": refreshToken], encoding: JSONEncoding.default)
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
