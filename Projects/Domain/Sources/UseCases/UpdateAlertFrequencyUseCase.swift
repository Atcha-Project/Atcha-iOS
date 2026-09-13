public protocol UpdateAlertFrequencyUseCase: Sendable {
    func execute(frequencies: [Int]) async throws
}

public struct DefaultUpdateAlertFrequencyUseCase: UpdateAlertFrequencyUseCase {
    private let userRepository: any UserRepository

    public init(userRepository: any UserRepository) {
        self.userRepository = userRepository
    }

    public func execute(frequencies: [Int]) async throws {
        try await userRepository.updateAlertFrequencies(frequencies)
    }
}
