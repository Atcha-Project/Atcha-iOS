//
//  UserRepository.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

protocol UserRepository {
    func fetchUser() async throws -> User
}
