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
                headers: headers
            )
        )
    }
    
    func observeCourseStream(_ request: CourseSearchRequest) -> AsyncThrowingStream<CourseSearchResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                await self.startStream(request, continuation: continuation)
            }
        }
    }

    private func startStream(
        _ request: CourseSearchRequest,
        continuation: AsyncThrowingStream<CourseSearchResponse, Error>.Continuation
    ) async {
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
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if httpResponse.statusCode == 401 {
                if let newToken = await refreshToken() {
                    AppDIContainer.shared.tokenStorage.accessToken = newToken
                    await startStream(request, continuation: continuation)
                    return
                } else {
                    continuation.finish(throwing: NSError(domain: "CourseRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "토큰 재발급 실패"]))
                    return
                }
            }
            
            for try await line in bytes.lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmedLine.starts(with: "data:") else { continue }
                
                let jsonString = trimmedLine.replacingOccurrences(of: "data:", with: "").trimmingCharacters(in: .whitespaces)
                if let data = jsonString.data(using: .utf8) {
                    if let decoded = try? JSONDecoder().decode(CourseSearchResponse.self, from: data) {
                        continuation.yield(decoded)
                    }
                }
            }
            
            continuation.finish()
        } catch {
            continuation.finish(throwing: error)
        }
    }

    private func refreshToken() async -> String? {
        guard let refreshToken = AppDIContainer.shared.tokenStorage.refreshToken else { return nil }
        let url = URL(string: "https://atcha.p-e.kr/api/auth/reissue")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            
            let decoded = try JSONDecoder().decode(APIResponse<RefreshTokenResponse>.self, from: data)
            return decoded.result?.accessToken
        } catch {
            print("refreshToken 실패: \(error)")
            return nil
        }
    }
}
