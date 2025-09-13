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
                    "endLon": request.endLon
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
            URLQueryItem(name: "endLon", value: "\(request.endLon)")
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
                if let tokens = await refreshToken() {
                    AppDIContainer.shared.tokenStorage.accessToken = tokens.accessToken
                    AppDIContainer.shared.tokenStorage.refreshToken = tokens.refreshToken
                    await startStream(request, continuation: continuation)
                    return
                } else {
                    continuation.finish(throwing: NSError(domain: "CourseRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "토큰 재발급 실패"]))
                    return
                }
            }
            
            let parser = SSEParser()
            
            for try await byte in bytes {
                // 바이트 단위로 들어오므로 Data로 감싸서 누적
                let events = parser.feed(Data([byte]))
                for event in events {
                    guard !event.data.isEmpty,
                          let payload = event.data.data(using: .utf8) else {
                        continue
                    }
                    
                    do {
                        let decoded = try JSONDecoder().decode(CourseSearchResponse.self, from: payload)
                        continuation.yield(decoded)
                        print(decoded)
                    } catch {
                        print("❌ SSE Decode 실패:", error)
                    }
                }
            }
            
            continuation.finish()
        } catch {
            continuation.finish(throwing: error)
        }
    }
    
    private func refreshToken() async -> (accessToken: String, refreshToken: String?)? {
        guard let refreshToken = AppDIContainer.shared.tokenStorage.refreshToken else { return nil }
        let url = URL(string: "https://atcha.p-e.kr/api/auth/reissue")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            
            let decoded = try JSONDecoder().decode(APIResponse<RefreshTokenResponse>.self, from: data)
            guard let result = decoded.result else { return nil }
            
            let newAccess = result.accessToken
            let newRefresh = result.refreshToken
            
            return (accessToken: newAccess, refreshToken: newRefresh)
        } catch {
            print("refreshToken 실패: \(error)")
            return nil
        }
    }
}
