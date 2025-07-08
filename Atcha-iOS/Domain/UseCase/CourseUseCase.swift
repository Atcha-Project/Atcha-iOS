//
//  CourseUseCase.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/7/25.
//

import Foundation

protocol CourseUseCase {
    // 경로 탐색
    func courseSearch(_ request: CourseSearchRequest) async throws -> [Course]
}

final class CourseUseCaseImpl: CourseUseCase {
    private let repository: CourseRepository
    
    init(repository: CourseRepository) {
        self.repository = repository
    }
    
    // 경로 탐색
    func courseSearch(_ request: CourseSearchRequest) async throws -> [Course] {
        
        return try await repository.courseSearch(request)
    }
}
