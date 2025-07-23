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
    func observeCourseStream(_ request: CourseSearchRequest) -> AsyncThrowingStream<Course, Error>
}

final class CourseUseCaseImpl: CourseUseCase {
    private let repository: CourseRepository
    
    init(repository: CourseRepository) {
        self.repository = repository
    }
    
    // 경로 탐색
    func courseSearch(_ request: CourseSearchRequest) async throws -> [Course] {
        return try await repository.courseSearch(request).compactMap { $0.toEntity() }
    }
    
    // 경로 탐색 스트리밍 방식
    func observeCourseStream(_ request: CourseSearchRequest) -> AsyncThrowingStream<Course, Error> {
        let stream = repository.observeCourseStream(request)
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await courseResponse in stream {
                        let entity = courseResponse.toEntity()
                        continuation.yield(entity)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
