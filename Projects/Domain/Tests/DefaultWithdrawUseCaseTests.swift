@testable import Domain
import Synchronization
import Testing

private final class WithdrawRecorder: Sendable {
    private let events = Mutex<[String]>([])

    func record(_ event: String) { events.withLock { $0.append(event) } }
    var log: [String] { events.withLock { $0 } }
}

private struct StubUserRepository: UserRepository {
    let recorder: WithdrawRecorder
    var withdrawError: (any Error)?

    func fetchMe() async throws -> UserProfile {
        UserProfile(
            userID: nil, providerID: nil, nickname: nil,
            address: nil, coordinate: nil, appVersion: nil
        )
    }

    func updateHomeAddress(address: String?, coordinate: Coordinate?) async throws {}

    func updateAlertFrequencies(_ frequencies: [Int]) async throws {}

    func withdraw(reason: String?) async throws {
        recorder.record("withdraw(\(reason ?? "nil"))")
        if let withdrawError { throw withdrawError }
    }
}

private struct StubSessionEnding: SessionEnding {
    let recorder: WithdrawRecorder

    func endSession() async { recorder.record("endSession") }
    func invalidateLocalSession() async { recorder.record("invalidate") }
}

private struct WithdrawServerError: Error {}

struct DefaultWithdrawUseCaseTests {
    private let recorder = WithdrawRecorder()

    /// 탈퇴가 서버에서 성공한 뒤에만 로컬 세션을 무효화한다.
    @Test
    func execute_success_withdrawsThenInvalidatesLocalSession() async throws {
        let sut = DefaultWithdrawUseCase(
            userRepository: StubUserRepository(recorder: recorder),
            sessionEnding: StubSessionEnding(recorder: recorder)
        )

        try await sut.execute(reason: "서비스 미사용")

        #expect(recorder.log == ["withdraw(서비스 미사용)", "invalidate"])
    }

    /// 서버 탈퇴 실패 시 세션을 보존한다 — 재시도할 수 있어야 한다.
    @Test
    func execute_serverFailure_propagatesAndKeepsSession() async {
        let sut = DefaultWithdrawUseCase(
            userRepository: StubUserRepository(
                recorder: recorder, withdrawError: WithdrawServerError()
            ),
            sessionEnding: StubSessionEnding(recorder: recorder)
        )

        await #expect(throws: WithdrawServerError.self) {
            try await sut.execute(reason: nil)
        }

        #expect(recorder.log == ["withdraw(nil)"])
    }
}
