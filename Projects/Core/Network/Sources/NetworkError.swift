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

extension NetworkError: CustomDebugStringConvertible {
    /// 진단용 한 줄. transport/offline이 URLError 코드를 삼키면 "타임아웃(-1001)"과
    /// "호스트에 연결 못 함(-1004)", "TLS 실패(-1200)"가 구분되지 않는다 — 원인이
    /// 앱인지 서버인지 네트워크인지 가르는 첫 단서라 코드를 그대로 노출한다.
    public var debugDescription: String {
        switch self {
        case .invalidURL:
            "invalidURL"
        case let .offline(underlying):
            "offline(\(Self.describe(underlying)))"
        case let .transport(underlying):
            "transport(\(Self.describe(underlying)))"
        case .invalidResponse:
            "invalidResponse(non-HTTP)"
        case let .unacceptableStatus(code, data):
            "unacceptableStatus(\(code), \(data.count)B)"
        case let .decoding(underlying):
            "decoding(\(underlying))"
        }
    }

    private static func describe(_ error: any Error) -> String {
        guard let urlError = error as? URLError else { return "\(error)" }
        return "URLError \(urlError.code.rawValue) \(urlError.localizedDescription)"
    }
}
