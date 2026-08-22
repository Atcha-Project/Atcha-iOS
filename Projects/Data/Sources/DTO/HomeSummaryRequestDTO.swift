public struct HomeSummaryRequestDTO: Encodable, Sendable {
    public let userID: String

    public init(userID: String) {
        self.userID = userID
    }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
    }
}
