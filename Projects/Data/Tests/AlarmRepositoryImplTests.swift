@testable import AtchaData
import CoreNetwork
import Domain
import Foundation
import Testing

private struct StubNetworkClient: NetworkClient {
    let result: Result<Data, NetworkError>

    func data(for endpoint: any Endpoint) async throws -> Data {
        try result.get()
    }

    func request<Response: Decodable & Sendable>(
        _ endpoint: any Endpoint,
        as _: Response.Type
    ) async throws -> Response {
        try JSONDecoder().decode(Response.self, from: result.get())
    }
}

/// 2026-09-25 실측으로 확인한 서버 응답을 그대로 고정한다.
struct AlarmRepositoryImplTests {
    /// 서버가 "등록된 알람 없음"을 알리는 실제 응답:
    /// `404 {"responseCode":"URT_001","message":"id(1010) 유저가 등록한 경로를 찾을 수 없습니다."}`
    ///
    /// 이걸 throw로 흘리면 조회 실패와 구분되지 않아, 상류(Reconciler)가 "못 물어봤다"로
    /// 해석해 세션을 계속 붙든다.
    @Test
    func refresh_urt001_isNotRegisteredRatherThanFailure() async throws {
        let body = Data(#"{"responseCode":"URT_001","message":"id(1010) 유저가 등록한 경로를 찾을 수 없습니다."}"#.utf8)
        let sut = AlarmRepositoryImpl(
            networkClient: StubNetworkClient(result: .failure(.unacceptableStatus(code: 404, data: body)))
        )

        #expect(try await sut.refresh() == .notRegistered)
    }

    @Test
    func refresh_success_returnsRegisteredInfo() async throws {
        let body = Data(#"{"responseCode":"SUCCESS","result":{"lastRouteId":"route-1","isReal":"true"}}"#.utf8)
        let sut = AlarmRepositoryImpl(
            networkClient: StubNetworkClient(result: .success(body))
        )

        #expect(try await sut.refresh().info?.lastRouteId == "route-1")
    }

    /// 다른 에러 코드는 **여전히 throw여야 한다** — URT_001만 정상 상태다.
    @Test
    func refresh_otherServerError_stillThrows() async {
        let body = Data(#"{"responseCode":"REQ_002","message":"Authorization 헤더가 없습니다"}"#.utf8)
        let sut = AlarmRepositoryImpl(
            networkClient: StubNetworkClient(result: .failure(.unacceptableStatus(code: 401, data: body)))
        )

        await #expect(throws: ServerError.self) {
            _ = try await sut.refresh()
        }
    }
}
