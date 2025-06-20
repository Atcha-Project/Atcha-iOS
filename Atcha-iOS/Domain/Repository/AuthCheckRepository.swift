//
//  AuthCheckRepository.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/21/25.
//

import Foundation

protocol AuthCheckRepository {
    func checkMemberRegistration(_ request: AuthCheckRequest) async throws -> AuthCheckResponse
}
