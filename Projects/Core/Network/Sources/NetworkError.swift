import Foundation

public enum NetworkError: Error, Sendable {
    case invalidURL
    /// 연결 자체가 없음(Phase 16) — URLError .notConnectedToInternet / .dataNotAllowed.
    /// 즉시 재시도해도 재실패라 재시도 대상이 아니고, 스플래시 실패 문구 분기의 근거다.
    /// .networkConnectionLost는 일시 장애(킵얼라이브 소켓 끊김 등)로 보고 transport에
    /// 남긴다 — 멱등 GET 1회 재시도로 살리는 쪽이 맞다.
    case offline(underlying: any Error)
    case transport(underlying: any Error)
    case invalidResponse
    case unacceptableStatus(code: Int, data: Data)
    case decoding(underlying: any Error)

    /// 전송 실패 분류 단일 지점 — 클라이언트가 URLSession 에러를 이 함수로만 감싼다.
    public static func classifyingTransport(_ error: any Error) -> NetworkError {
        switch (error as? URLError)?.code {
        case .notConnectedToInternet, .dataNotAllowed:
            .offline(underlying: error)
        default:
            .transport(underlying: error)
        }
    }

    public var isOffline: Bool {
        if case .offline = self { return true }
        return false
    }
}
