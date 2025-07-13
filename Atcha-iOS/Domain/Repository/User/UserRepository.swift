//
//  UserRepository.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

protocol UserRepository {
    // MARK: - 유저 정보 조회
    func fetchUser() async throws -> UserInfo
    
    // MARK: - 회원 가입
    func signUp(_ request: SignUpRequest) async throws -> SignUpResponse
    
    // MARK: - 로그인
    func login(_ request: LoginRequest) async throws -> LoginResponse
    
    // MARK: - 가입 여부 조회
    func checkRegistration(_ request: AuthCheckRequest) async throws -> AuthCheckResponse
}
