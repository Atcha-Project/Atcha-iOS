public protocol WithdrawUseCase: Sendable {
    func execute(reason: String?) async throws
}

public struct DefaultWithdrawUseCase: WithdrawUseCase {
    private let userRepository: any UserRepository
    private let sessionEnding: any SessionEnding

    public init(userRepository: any UserRepository, sessionEnding: any SessionEnding) {
        self.userRepository = userRepository
        self.sessionEnding = sessionEnding
    }

    public func execute(reason: String?) async throws {
        // 탈퇴가 서버에서 성공한 뒤에만 로컬 세션을 무효화한다 —
        // 실패 시 세션을 보존해야 사용자가 재시도할 수 있다.
        try await userRepository.withdraw(reason: reason)
        await sessionEnding.invalidateLocalSession()
    }
}
