@testable import Domain
import Synchronization
import Testing

private final class GuestRecorder: Sendable {
    private let events = Mutex<[String]>([])
    func record(_ event: String) { events.withLock { $0.append(event) } }
    var log: [String] { events.withLock { $0 } }
}

private struct StubAuthRepository: AuthRepository {
    let recorder: GuestRecorder
    var fails = false

    func issueGuestSession(deviceID: String, fcmToken: String?) async throws -> LoginSession {
        recorder.record("issue(\(deviceID),\(fcmToken ?? "nil"))")
        if fails { throw GuestFailure() }
        return LoginSession(userID: 7, accessToken: "access", refreshToken: "refresh")
    }
}

private struct StubSessionStore: SessionStoring {
    let recorder: GuestRecorder
    func store(accessToken: String, refreshToken: String) async throws {
        recorder.record("store(\(accessToken),\(refreshToken))")
    }
}

private struct StubDeviceIdentifier: DeviceIdentifierProviding {
    func deviceID() throws -> String { "device-1" }
}

private struct StubPushTokenProvider: PushTokenProviding {
    let token: String?
    func currentPushToken() async -> String? { token }
}

private struct GuestFailure: Error {}

struct DefaultIssueGuestSessionUseCaseTests {
    private let recorder = GuestRecorder()

    @Test
    func execute_issuesWithDeviceIDAndPushToken_thenStoresTokens() async throws {
        let sut = DefaultIssueGuestSessionUseCase(
            authRepository: StubAuthRepository(recorder: recorder),
            sessionStore: StubSessionStore(recorder: recorder),
            deviceIdentifier: StubDeviceIdentifier(),
            pushTokenProvider: StubPushTokenProvider(token: "fcm")
        )

        try await sut.execute()

        #expect(recorder.log == ["issue(device-1,fcm)", "store(access,refresh)"])
    }

    /// 발급 실패 시 아무것도 저장하지 않는다 — 스플래시가 재시도 UI를 띄운다.
    @Test
    func execute_failure_propagatesWithoutStoring() async {
        let sut = DefaultIssueGuestSessionUseCase(
            authRepository: StubAuthRepository(recorder: recorder, fails: true),
            sessionStore: StubSessionStore(recorder: recorder),
            deviceIdentifier: StubDeviceIdentifier(),
            pushTokenProvider: StubPushTokenProvider(token: nil)
        )

        await #expect(throws: GuestFailure.self) { try await sut.execute() }
        #expect(recorder.log == ["issue(device-1,nil)"])
    }
}
