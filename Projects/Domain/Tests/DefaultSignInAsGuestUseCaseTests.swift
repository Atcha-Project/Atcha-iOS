@testable import Domain
import Foundation
import Synchronization
import Testing

private final class GuestRecorder: Sendable {
    private let events = Mutex<[String]>([])

    func record(_ event: String) { events.withLock { $0.append(event) } }
    var log: [String] { events.withLock { $0 } }
}

private struct StubGuestAuthRepository: AuthRepository {
    let recorder: GuestRecorder
    var session = LoginSession(userID: 7, accessToken: "GA", refreshToken: "GR")
    var guestError: (any Error)?

    func signInAsGuest(deviceID: String, fcmToken: String?) async throws -> LoginSession {
        recorder.record("guest(device:\(deviceID)/fcm:\(fcmToken ?? "nil"))")
        if let guestError { throw guestError }
        return session
    }

    // 게스트 스위트에서는 소셜 경로를 쓰지 않는다.
    func checkRegistration(credential: SocialCredential) async throws -> Bool { true }

    func login(credential: SocialCredential, fcmToken: String?) async throws -> LoginSession {
        session
    }

    func signUp(
        credential: SocialCredential,
        form: SignUpForm,
        fcmToken: String?
    ) async throws -> LoginSession {
        session
    }
}

private struct StubGuestSessionStore: SessionStoring {
    let recorder: GuestRecorder
    var error: (any Error)?

    func store(accessToken: String, refreshToken: String) async throws {
        recorder.record("store(\(accessToken)/\(refreshToken))")
        if let error { throw error }
    }
}

private struct StubDeviceIdentifierProvider: DeviceIdentifierProviding {
    var deviceID = "DEVICE-1"

    func currentDeviceID() async -> String { deviceID }
}

private struct StubGuestPushTokenProvider: PushTokenProviding {
    var token: String?

    func currentPushToken() async -> String? { token }
}

private struct GuestStoreError: Error {}
private struct GuestAuthError: Error {}

struct DefaultSignInAsGuestUseCaseTests {
    private let recorder = GuestRecorder()

    private func makeSUT(
        repository: StubGuestAuthRepository? = nil,
        store: StubGuestSessionStore? = nil,
        deviceID: String = "DEVICE-1",
        pushToken: String? = nil
    ) -> DefaultSignInAsGuestUseCase {
        DefaultSignInAsGuestUseCase(
            authRepository: repository ?? StubGuestAuthRepository(recorder: recorder),
            sessionStore: store ?? StubGuestSessionStore(recorder: recorder),
            deviceIdentifierProvider: StubDeviceIdentifierProvider(deviceID: deviceID),
            pushTokenProvider: StubGuestPushTokenProvider(token: pushToken)
        )
    }

    /// 게스트 부트스트랩은 deviceId로 토큰을 받아 세션에 채택하는 것이 전부다 —
    /// 소셜 인가·가입 여부 확인·위치 조회가 개입하지 않는다.
    @Test
    func execute_sendsDeviceIDThenStoresSession() async throws {
        let sut = makeSUT(pushToken: "FCM")

        try await sut.execute()

        #expect(recorder.log == [
            "guest(device:DEVICE-1/fcm:FCM)",
            "store(GA/GR)",
        ])
    }

    /// 알림 권한 전이면 FCM 토큰이 없는 것이 정상 — 빈 문자열로 강등하지 않고 nil을 넘긴다.
    @Test
    func execute_noPushToken_passesNil() async throws {
        let sut = makeSUT()

        try await sut.execute()

        #expect(recorder.log == [
            "guest(device:DEVICE-1/fcm:nil)",
            "store(GA/GR)",
        ])
    }

    /// 같은 기기는 항상 같은 deviceId를 보낸다(서버가 같은 계정을 돌려주는 근거).
    @Test
    func execute_usesProvidedDeviceIdentifier() async throws {
        let sut = makeSUT(deviceID: "DEVICE-STABLE")

        try await sut.execute()

        #expect(recorder.log.first == "guest(device:DEVICE-STABLE/fcm:nil)")
    }

    /// 서버 실패는 그대로 전파되고 세션은 채택되지 않는다 — 스플래시가 실패 문구를 띄울 근거.
    @Test
    func execute_guestFailure_propagatesWithoutStore() async {
        let sut = makeSUT(
            repository: StubGuestAuthRepository(recorder: recorder, guestError: GuestAuthError())
        )

        await #expect(throws: GuestAuthError.self) {
            try await sut.execute()
        }

        #expect(recorder.log == ["guest(device:DEVICE-1/fcm:nil)"])
    }

    @Test
    func execute_storeFailure_propagates() async {
        let sut = makeSUT(store: StubGuestSessionStore(recorder: recorder, error: GuestStoreError()))

        await #expect(throws: GuestStoreError.self) {
            try await sut.execute()
        }

        #expect(recorder.log.count == 2)
    }
}
