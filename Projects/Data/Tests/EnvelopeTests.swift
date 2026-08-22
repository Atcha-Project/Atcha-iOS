@testable import AtchaData
import CoreNetwork
import Domain
import Foundation
import Testing

private struct PingEndpoint: Endpoint {
    var path: String { "/ping" }
    var method: HTTPMethod { .get }
}

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

struct EnvelopeTests {
    @Test
    func requestEnveloped_success_unwrapsResult() async throws {
        let body = Data(#"{"responseCode":"SUCCESS","result":{"lastRouteId":"route-1","isReal":"true"}}"#.utf8)
        let client = StubNetworkClient(result: .success(body))
        let dto: AlarmRefreshResponseDTO = try await client.requestEnveloped(PingEndpoint())
        #expect(dto.lastRouteId == "route-1")
        #expect(dto.isReal == "true")
    }

    @Test
    func requestEnveloped_nonSuccessCode_throwsServerErrorWithMessage() async {
        let body = Data(#"{"responseCode":"LRT_001","message":"오늘 막차가 종료되었습니다","result":null}"#.utf8)
        let client = StubNetworkClient(result: .success(body))
        await #expect(throws: ServerError(code: "LRT_001", message: "오늘 막차가 종료되었습니다")) {
            let _: AlarmRefreshResponseDTO = try await client.requestEnveloped(PingEndpoint())
        }
    }

    @Test
    func requestEnveloped_nullResultForNonEmptyType_throws() async {
        let body = Data(#"{"responseCode":"SUCCESS","result":null}"#.utf8)
        let client = StubNetworkClient(result: .success(body))
        await #expect(throws: NetworkError.self) {
            let _: AlarmRefreshResponseDTO = try await client.requestEnveloped(PingEndpoint())
        }
    }

    @Test
    func requestEnveloped_nullResultForEmptyType_succeeds() async throws {
        let body = Data(#"{"responseCode":"SUCCESS"}"#.utf8)
        let client = StubNetworkClient(result: .success(body))
        let _: APIEmptyResult = try await client.requestEnveloped(PingEndpoint())
    }

    @Test
    func requestEnveloped_nonEnvelopeBodyForEmptyType_succeeds() async throws {
        let client = StubNetworkClient(result: .success(Data()))
        let _: APIEmptyResult = try await client.requestEnveloped(PingEndpoint())
    }

    @Test
    func requestEnveloped_unacceptableStatusWithEnvelopeBody_throwsServerError() async {
        let body = Data(#"{"responseCode":"URT_001","message":"등록된 경로가 없습니다","path":"/routes/user-routes/refresh"}"#.utf8)
        let client = StubNetworkClient(result: .failure(.unacceptableStatus(code: 404, data: body)))
        await #expect(throws: ServerError(code: "URT_001", message: "등록된 경로가 없습니다")) {
            let _: AlarmRefreshResponseDTO = try await client.requestEnveloped(PingEndpoint())
        }
    }

    @Test
    func requestEnveloped_unacceptableStatusWithoutEnvelopeBody_rethrowsNetworkError() async {
        let client = StubNetworkClient(result: .failure(.unacceptableStatus(code: 500, data: Data())))
        await #expect(throws: NetworkError.self) {
            let _: AlarmRefreshResponseDTO = try await client.requestEnveloped(PingEndpoint())
        }
    }
}
