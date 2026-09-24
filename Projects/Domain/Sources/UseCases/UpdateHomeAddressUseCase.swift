public enum UpdateHomeAddressError: Error, Equatable {
    /// 서비스 지역 밖 — 레거시 토스트 "앗차는 현재 서울, 경기, 인천에서만 이용 가능해요".
    case outOfServiceRegion
}

public protocol UpdateHomeAddressUseCase: Sendable {
    func execute(address: String?, coordinate: Coordinate) async throws
}

public struct DefaultUpdateHomeAddressUseCase: UpdateHomeAddressUseCase {
    private let userRepository: any UserRepository
    private let placeRepository: any PlaceRepository

    public init(userRepository: any UserRepository, placeRepository: any PlaceRepository) {
        self.userRepository = userRepository
        self.placeRepository = placeRepository
    }

    public func execute(address: String?, coordinate: Coordinate) async throws {
        // 서비스 지역 밖의 집은 막차 검색이 성립하지 않는다 — 저장 전에 거른다(레거시 규칙).
        guard try await placeRepository.isServiceRegion(coordinate) else {
            throw UpdateHomeAddressError.outOfServiceRegion
        }
        try await userRepository.updateHomeAddress(address: address, coordinate: coordinate)
    }
}
