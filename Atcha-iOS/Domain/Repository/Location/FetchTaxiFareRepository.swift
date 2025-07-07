//
//  FetchTaxiFareRepository.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/7/25.
//

import Foundation

protocol FetchTaxiFareRepository {
    func fetchTaxiFare(request: FetchTaxiFareRequest) async throws -> Double
}
