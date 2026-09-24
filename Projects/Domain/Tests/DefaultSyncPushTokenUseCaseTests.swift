@testable import Domain
import Synchronization
import Testing

private final class SpyPushTokenRepository: PushTokenRepository {
    private let sent = Mutex<[String]>([])
    private let failing = Mutex(false)
    var log: [String] { sent.withLock { $0 } }
    func setFailing(_ value: Bool) { failing.withLock { $0 = value } }

    func register(token: String) async throws {
        sent.withLock { $0.append(token) }
        if failing.withLock({ $0 }) { throw SpyFailure() }
    }
}

private struct SpyFailure: Error {}

struct DefaultSyncPushTokenUseCaseTests {
    @Test
    func execute_sameTokenTwice_sendsOnce() async {
        let repository = SpyPushTokenRepository()
        let sut = DefaultSyncPushTokenUseCase(repository: repository)

        await sut.execute(token: "a")
        await sut.execute(token: "a")
        await sut.execute(token: "b")

        #expect(repository.log == ["a", "b"])
    }

    /// 실패한 토큰은 기억하지 않는다 — 다음 트리거가 재시도가 된다.
    @Test
    func execute_failure_retriesNextTime() async {
        let repository = SpyPushTokenRepository()
        repository.setFailing(true)
        let sut = DefaultSyncPushTokenUseCase(repository: repository)

        await sut.execute(token: "a")
        repository.setFailing(false)
        await sut.execute(token: "a")

        #expect(repository.log == ["a", "a"])
    }

    /// 계정이 바뀌면 같은 토큰도 다시 보내야 한다.
    @Test
    func reset_allowsResend() async {
        let repository = SpyPushTokenRepository()
        let sut = DefaultSyncPushTokenUseCase(repository: repository)

        await sut.execute(token: "a")
        sut.reset()
        await sut.execute(token: "a")

        #expect(repository.log == ["a", "a"])
    }
}
