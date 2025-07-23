//
//  CourseRepository.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/7/25.
//

import Foundation

protocol CourseRepository {
    // 경로 탐색
    func courseSearch(_ request: CourseSearchRequest) async throws -> [CourseSearchResponse]
    
    // 경로 탐색 스트리밍 방식
    func observeCourseStream(_ request: CourseSearchRequest) -> AsyncThrowingStream<CourseSearchResponse, Error>
}
