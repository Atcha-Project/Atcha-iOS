public protocol GetUserProfileUseCase: Sendable {
    func execute() async throws -> UserProfile
}

public struct DefaultGetUserProfileUseCase: GetUserProfileUseCase {
    private let userRepository: any UserRepository

    public init(userRepository: any UserRepository) {
        self.userRepository = userRepository
    }

    public func execute() async throws -> UserProfile {
        try await userRepository.fetchMe()
    }
}
