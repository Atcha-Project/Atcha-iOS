import Domain

public struct HomeSummaryResponseDTO: Decodable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String?

    public func toEntity() -> HomeSummary {
        HomeSummary(id: id, title: title, subtitle: subtitle ?? "")
    }
}
