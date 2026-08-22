public protocol HomeRepository: Sendable {
    func fetchHomeSummary() async throws -> HomeSummary
}
