//
//  FetchTaxiFareUseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/7/25.
//

import Foundation

protocol FetchTaxiFareUseCase {
    func fetchTaxiFare(request: FetchTaxiFareRequest) async throws -> Double
}

final class FetchTaxiFareUseCaseImpl: FetchTaxiFareUseCase {
    private let repository: FetchTaxiFareRepository
    
    init(repository: FetchTaxiFareRepository) {
        self.repository = repository
    }
    
    func fetchTaxiFare(request: FetchTaxiFareRequest) async throws -> Double {
        return try await repository.fetchTaxiFare(request: request)
    }
}
