//
//  CourseRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/7/25.
//

import Foundation
import Alamofire

final class CourseRepositoryImpl: CourseRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func courseSearch(_ request: CourseSearchRequest) async throws -> [CourseSearchResponse] {
        guard let token = AppDIContainer.shared.tokenStorage.accessToken else {
            throw NSError(domain: "CourseRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "인증 토큰이 없습니다."])
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/routes/last-routes",
                method: .get,
                parameters: [
                    "startLat": request.startLat,
                    "startLon": request.startLon,
                    "endLat": request.endLat,
                    "endLon": request.endLon,
                    "sortType": request.sortType
                ],
                headers: headers,
            ))
    }
    
    func observeCourseStream(_ request: CourseSearchRequest) -> AsyncThrowingStream<CourseSearchResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard let token = AppDIContainer.shared.tokenStorage.accessToken else {
                    continuation.finish(throwing: NSError(domain: "CourseRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "인증 토큰이 없습니다."]))
                    return
                }

                var urlComponents = URLComponents(string: "https://atcha.p-e.kr/api/routes/v3/last-routes/stream")!
                urlComponents.queryItems = [
                    URLQueryItem(name: "startLat", value: "\(request.startLat)"),
                    URLQueryItem(name: "startLon", value: "\(request.startLon)"),
                    URLQueryItem(name: "endLat", value: "\(request.endLat)"),
                    URLQueryItem(name: "endLon", value: "\(request.endLon)"),
                    URLQueryItem(name: "sortType", value: "\(request.sortType)")
                ]

                var urlRequest = URLRequest(url: urlComponents.url!)
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        throw URLError(.badServerResponse)
                    }

                    for try await line in bytes.lines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

                        guard trimmedLine.starts(with: "data:") else {
                            print("무시된 라인 (data: 아님): \(trimmedLine)")
                            continue
                        }

                        let jsonString = trimmedLine.replacingOccurrences(of: "data:", with: "").trimmingCharacters(in: .whitespaces)

                        guard let data = jsonString.data(using: .utf8) else {
                            print("JSON 문자열 → Data 변환 실패")
                            continue
                        }

                        do {
                            let decoded = try JSONDecoder().decode(CourseSearchResponse.self, from: data)
                            continuation.yield(decoded)
                        } catch {
                            print("디코딩 실패: \(error)")
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
