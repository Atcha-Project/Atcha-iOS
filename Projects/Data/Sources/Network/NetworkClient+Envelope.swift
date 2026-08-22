import CoreNetwork
import Domain
import Foundation

private let successResponseCode = "SUCCESS"

extension NetworkClient {
    /// envelope를 해체해 result만 돌려준다. responseCode ≠ SUCCESS면 `ServerError`.
    func requestEnveloped<T: Decodable & Sendable>(
        _ endpoint: any Endpoint,
        as _: T.Type = T.self
    ) async throws -> T {
        let data: Data
        do {
            data = try await self.data(for: endpoint)
        } catch let error as NetworkError {
            // 비즈니스 에러 코드는 non-2xx HTTP의 body envelope로 온다 (레거시 실측).
            throw serverError(from: error) ?? error
        }

        let envelope: APIResponse<T>
        do {
            envelope = try JSONDecoder().decode(APIResponse<T>.self, from: data)
        } catch {
            // 레거시 규약: 2xx + 빈 응답 기대(T == APIEmptyResult)면 본문 형태와 무관하게 성공.
            if let empty = APIEmptyResult() as? T { return empty }
            throw NetworkError.decoding(underlying: error)
        }

        guard envelope.responseCode == successResponseCode else {
            let message = (try? JSONDecoder().decode(APIFailureResponse.self, from: data))?.message
            throw ServerError(code: envelope.responseCode, message: message)
        }
        if let result = envelope.result { return result }
        if let empty = APIEmptyResult() as? T { return empty }
        throw NetworkError.decoding(underlying: MissingResultError())
    }
}

private func serverError(from error: NetworkError) -> ServerError? {
    guard case let .unacceptableStatus(_, data) = error,
          let failure = try? JSONDecoder().decode(APIFailureResponse.self, from: data),
          let code = failure.responseCode
    else { return nil }
    return ServerError(code: code, message: failure.message)
}
