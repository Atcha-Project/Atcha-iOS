public protocol UpdateHomeAddressUseCase: Sendable {
    func execute(address: String?, coordinate: Coordinate?) async throws
}

public struct DefaultUpdateHomeAddressUseCase: UpdateHomeAddressUseCase {
    private let userRepository: any UserRepository

    public init(userRepository: any UserRepository) {
        self.userRepository = userRepository
    }

    public func execute(address: String?, coordinate: Coordinate?) async throws {
        try await userRepository.updateHomeAddress(address: address, coordinate: coordinate)
    }
}
