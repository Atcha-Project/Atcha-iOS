/// 서버가 envelope의 responseCode로 알려온 비즈니스 에러.
public struct ServerError: Error, Equatable, Sendable {
    public let code: String
    public let message: String?

    public init(code: String, message: String? = nil) {
        self.code = code
        self.message = message
    }
}
