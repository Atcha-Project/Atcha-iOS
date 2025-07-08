//
//  CourseRepository.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/7/25.
//

import Foundation

protocol CourseRepository {
    // 경로 탐색
    func courseSearch(_ request: CourseSearchRequest) async throws -> [Course]
}
