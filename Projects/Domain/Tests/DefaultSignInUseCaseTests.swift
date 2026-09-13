@testable import Domain
import Foundation
import Synchronization
import Testing

/// 스텁 공유 기록기 — 호출 순서·횟수·전달 인자를 한 곳에서 검증한다.
private final class SignInRecorder: Sendable {
    private let events = Mutex<[String]>([])

    func record(_ event: String) { events.withLock { $0.append(event) } }
    var log: [String] { events.withLock { $0 } }
    func count(of event: String) -> Int { log.count(where: { $0 == event }) }
}

private struct StubSocialLoginService: SocialLoginService {
    let recorder: SignInRecorder
    var result: Result<SocialCredential, SocialLoginError> =
        .success(SocialCredential(provider: .kakao, accessToken: "SOCIAL"))

    func authorize(provider: SocialLoginProvider) async throws -> SocialCredential {
        recorder.record("authorize")
        return try result.get()
    }
}

private struct StubAuthRepository: AuthRepository {
    let recorder: SignInRecorder
    var exists = true
    var session = LoginSession(userID: 1, accessToken: "SA", refreshToken: "SR")

    func checkRegistration(credential: SocialCredential) async throws -> Bool {
        recorder.record("check(\(credential.accessToken))")
        return exists
    }

    func login(credential: SocialCredential, fcmToken: String?) async throws -> LoginSession {
        recorder.record("login(fcm:\(fcmToken ?? "nil"))")
        return session
    }
}

private struct StubSessionStore: SessionStoring {
    let recorder: SignInRecorder
    var error: (any Error)?

    func store(accessToken: String, refreshToken: String) async throws {
        recorder.record("store(\(accessToken)/\(refreshToken))")
        if let error { throw error }
    }
}

private struct StubPushTokenProvider: PushTokenProviding {
    var token: String?

    func currentPushToken() async -> String? { token }
}

private struct StoreError: Error {}

struct DefaultSignInUseCaseTests {
    private let recorder = SignInRecorder()

    private func makeSUT(
        social: StubSocialLoginService? = nil,
        repository: StubAuthRepository? = nil,
        store: StubSessionStore? = nil,
        pushToken: String? = nil
    ) -> DefaultSignInUseCase {
        DefaultSignInUseCase(
            socialLoginService: social ?? StubSocialLoginService(recorder: recorder),
            authRepository: repository ?? StubAuthRepository(recorder: recorder),
            sessionStore: store ?? StubSessionStore(recorder: recorder),
            pushTokenProvider: StubPushTokenProvider(token: pushToken)
        )
    }

    @Test
    func execute_registered_runsAuthorizeCheckLoginStoreInOrder() async throws {
        let sut = makeSUT(pushToken: "FCM")

        let outcome = try await sut.execute(provider: .kakao)

        #expect(outcome == .success)
        #expect(recorder.log == [
            "authorize",
            "check(SOCIAL)",
            "login(fcm:FCM)",
            "store(SA/SR)",
        ])
    }

    @Test
    func execute_noPushToken_passesNilToLogin() async throws {
        let sut = makeSUT()

        _ = try await sut.execute(provider: .apple)

        #expect(recorder.count(of: "login(fcm:nil)") == 1)
    }

    @Test
    func execute_notRegistered_returnsNeedsSignUpWithoutLoginOrStore() async throws {
        let sut = makeSUT(repository: StubAuthRepository(recorder: recorder, exists: false))

        let outcome = try await sut.execute(provider: .kakao)

        #expect(outcome == .needsSignUp)
        #expect(recorder.log == ["authorize", "check(SOCIAL)"])
    }

    @Test
    func execute_authorizeCancelled_propagatesWithoutServerCalls() async {
        let sut = makeSUT(
            social: StubSocialLoginService(recorder: recorder, result: .failure(.cancelled))
        )

        await #expect(throws: SocialLoginError.cancelled) {
            try await sut.execute(provider: .kakao)
        }

        #expect(recorder.log == ["authorize"])
    }

    @Test
    func execute_storeFailure_propagates() async {
        let sut = makeSUT(store: StubSessionStore(recorder: recorder, error: StoreError()))

        await #expect(throws: StoreError.self) {
            try await sut.execute(provider: .kakao)
        }

        #expect(recorder.count(of: "store(SA/SR)") == 1)
    }
}
