public struct AlarmRegisterRequestDTO: Encodable, Sendable {
    public let lastRouteId: String

    public init(lastRouteId: String) {
        self.lastRouteId = lastRouteId
    }
}
