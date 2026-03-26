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
    private var tokenStorage: TokenStorage
    
    init(apiService: APIService, tokenStorage: TokenStorage) {
        self.apiService = apiService
        self.tokenStorage = tokenStorage
    }
    
    func courseSearch(_ routeId: String) async throws -> CourseSearchResponse {
        return try await apiService.request(Endpoint(path: "/routes/last-routes/\(routeId)", method: .get))
    }
    
    func courseSearch(_ request: CourseSearchRequest) async throws -> [CourseSearchResponse] {
        return try await apiService.request(
            Endpoint(
                path: "/routes/last-routes",
                method: .get,
                parameters: [
                    "startLat": request.startLat,
                    "startLon": request.startLon,
                    "endLat": request.endLat,
                    "endLon": request.endLon
                ]
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
        guard let token = tokenStorage.accessToken else {
            continuation.finish(throwing: NSError(domain: "CourseRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "인증 토큰이 없습니다."]))
            return
        }
        
        var urlComponents = URLComponents(string: "\(NetworkConstant.baseURL)/routes/v3/last-routes/stream")!
        urlComponents.queryItems = [
            URLQueryItem(name: "startLat", value: "\(request.startLat)"),
            URLQueryItem(name: "startLon", value: "\(request.startLon)"),
            URLQueryItem(name: "endLat", value: "\(request.endLat)"),
            URLQueryItem(name: "endLon", value: "\(request.endLon)")
        ]
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            // HTTP 401 체크는 제거 (서버가 200으로 주기 때문)
            if http.statusCode != 200 {
                continuation.finish(throwing: NSError(domain: "CourseRepository", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "SSE 연결 실패 (\(http.statusCode))"]))
                return
            }
            
            let parser = SSEParser()
            var receivedAny = false
            
            do {
                for try await byte in bytes {
                    receivedAny = true
                    let events = parser.feed(Data([byte]))
                    for event in events {
                        guard !event.data.isEmpty, let payload = event.data.data(using: .utf8) else { continue }
                        
                        // 1. 데이터 내부의 에러 코드 확인 (TOK_001)
                        if let errorCheck = try? JSONDecoder().decode(SSEErrorPayload.self, from: payload),
                           errorCheck.responseCode == "TOK_001" {
                            
                            if let tokens = await refreshToken() {
                                tokenStorage.accessToken = tokens.accessToken
                                if let rt = tokens.refreshToken { tokenStorage.refreshToken = rt }
                                print("재발급 성공 → 스트림 재연결")
                                // 현재 스트림을 종료하지 않고 새 연결 시도
                                await startStream(request, continuation: continuation)
                                return
                            } else {
                                continuation.finish(throwing: NSError(domain: "CourseRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "토큰 재발급 실패"]))
                                return
                            }
                        }
                        
                        // 2. 정상 데이터 디코딩
                        do {
                            let decoded = try JSONDecoder().decode(CourseSearchResponse.self, from: payload)
                            print("데이터 수신: \(decoded)")
                            continuation.yield(decoded)
                        } catch {
                            // 단순 텍스트나 핑 데이터인 경우 무시
                            print("SSE decode 실패 (데이터 무시):", error, "raw:", event.data)
                        }
                    }
                }
            } catch {
                print("SSE stream read error:", error)
                continuation.finish(throwing: error)
                return
            }
            
            if !receivedAny {
                continuation.finish(throwing: NSError(domain: "CourseRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "SSE에서 응답이 없습니다."]))
                return
            }
            
            continuation.finish()
        } catch {
            print("SSE open error:", error)
            continuation.finish(throwing: error)
        }
    }
    
    
    private func refreshToken() async -> (accessToken: String, refreshToken: String?)? {
        guard let refreshToken = tokenStorage.refreshToken else {
            print("refreshToken 없음")
            SessionController.shared.expireAndRouteToLogin()
            return nil
        }
        let url = URL(string: "\(NetworkConstant.baseURL)/auth/reissue")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                print("reissue: HTTPURLResponse 아님")
                //                SessionController.shared.expireAndRouteToLogin()
                return nil
            }
            
            // 200 아니면 바로 실패 처리
            guard http.statusCode == 200 else {
                if http.statusCode == 401 { print("reissue 401: refresh 만료/위조 가능") }
                SessionController.shared.expireAndRouteToLogin()
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let decoded = try decoder.decode(APIResponse<RefreshTokenResponse>.self, from: data)
                guard let result = decoded.result else {
                    print("reissue: result nil (responseCode=\(decoded.responseCode))")
                    //                    SessionController.shared.expireAndRouteToLogin()
                    return nil
                }
                return (accessToken: result.accessToken, refreshToken: result.refreshToken)
            } catch {
                print("reissue 디코딩 실패:", error)
                //                SessionController.shared.expireAndRouteToLogin()
                return nil
            }
            
        } catch {
            print("reissue 네트워크 오류:", error)
            //            SessionController.shared.expireAndRouteToLogin()
            return nil
        }
    }
}

struct SSEErrorPayload: Decodable {
    let responseCode: String?
    let message: String?
}
