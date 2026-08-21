import Foundation

public enum NetworkError: Error, Sendable {
    case invalidURL
    case transport(underlying: any Error)
    case invalidResponse
    case unacceptableStatus(code: Int, data: Data)
    case decoding(underlying: any Error)
}
