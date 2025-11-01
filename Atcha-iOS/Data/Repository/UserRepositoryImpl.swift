//
//  UserRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation
import Alamofire

final class UserRepositoryImpl: UserRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func fetchUser() async throws -> UserInfoResponse {
        return try await apiService.request(
            Endpoint(path: "\(NetworkConstant.baseURL)/members/me",
                     method: .get,
                     headers: ["X-Platform" : "iOS"])
        )
    }
    
    func signUp(_ request: SignUpRequest) async throws -> SignUpResponse {
        guard let providerToken = UserDefaultsWrapper.shared.string(forKey: UserDefaultsWrapper.Key.providerToken.rawValue) else {
            print("플랫폼 토큰 없음")
            throw NSError(domain: "SignUpError", code: -1, userInfo: [NSLocalizedDescriptionKey: "플랫폼 토큰 없음"])
        }
        
        return try await apiService.request(
            Endpoint(
                path: "\(NetworkConstant.baseURL)/auth/sign-up",
                method: .post,
                encoding: JSONEncoding.default,
                headers: ["Authorization": "Bearer \(providerToken)"]),
            body: request)
    }
    
    func signOut(_ request: WithdrawRequest) async throws -> APIEmptyResponse {
        return try await apiService.request(
            Endpoint(
                path: "\(NetworkConstant.baseURL)/members/me",
                method: .delete,
                encoding: JSONEncoding.default),
            body: request)
    }
    
    func login(_ request: LoginRequest) async throws -> LoginResponse {
        return try await apiService.request(
            Endpoint(
                path: "\(NetworkConstant.baseURL)/auth/login",
                method: .get,
                parameters: [
                    "provider": "\(request.provider)",
                    "fcmToken": AppDIContainer.shared.tokenStorage.fcmToken ?? ""
                ],
                headers: ["Authorization": "Bearer \(request.accessToken)"]
            )
        )
    }
    
    func logout() async throws -> APIEmptyResponse {
        return try await apiService.request(
            Endpoint(
                path: "\(NetworkConstant.baseURL)/auth/logout",
                method: .post
            )
        )
    }
    
    func checkRegistration(_ request: AuthCheckRequest) async throws -> AuthCheckResponse {
        return try await apiService.request(
            Endpoint(
                path: "\(NetworkConstant.baseURL)/auth/check",
                method: .get,
                parameters: ["provider": "\(request.provider)"],
                headers: ["Authorization": "Bearer \(request.accessToken)"]
            )
        )
    }
    
    func homePatch(_ request: HomePatchRequest) async throws -> UserInfoPatchResponse {
        return try await apiService.request(
            Endpoint(
                path: "\(NetworkConstant.baseURL)/members/me/home-address",
                method: .patch,
                encoding: JSONEncoding.default),
            body: request)
    }
    
    func pushAlarmPatch(_ request: PushAlarmPatchRequest) async throws -> UserInfoPatchResponse {
        return try await apiService.request(
            Endpoint(
                path: "\(NetworkConstant.baseURL)/members/me/alert-frequency",
                method: .patch,
                encoding: JSONEncoding.default),
            body: request)
    }
}
