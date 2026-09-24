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
    var signUpError: (any Error)?

    func checkRegistration(credential: SocialCredential) async throws -> Bool {
        recorder.record("check(\(credential.accessToken))")
        return exists
    }

    func login(credential: SocialCredential, fcmToken: String?) async throws -> LoginSession {
        recorder.record("login(fcm:\(fcmToken ?? "nil"))")
        return session
    }

    func signUp(
        credential: SocialCredential,
        form: SignUpForm,
        fcmToken: String?
    ) async throws -> LoginSession {
        recorder.record(
            "signUp(addr:\(form.address)/lat:\(form.coordinate.latitude)"
                + "/freq:\(form.alertFrequencies)/name:\(form.userName ?? "nil")"
                + "/fcm:\(fcmToken ?? "nil"))"
        )
        if let signUpError { throw signUpError }
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

private struct StubGetCurrentLocationUseCase: GetCurrentLocationUseCase {
    var result: Result<Coordinate, LocationError> =
        .success(Coordinate(latitude: 37.5, longitude: 127.0))

    func execute() async throws -> Coordinate {
        try result.get()
    }
}

private struct StubReverseGeocodeUseCase: ReverseGeocodeUseCase {
    var result: Result<Place, any Error> = .success(
        Place(name: "집앞", address: "서울 어딘가 1-2", coordinate: Coordinate(latitude: 37.5, longitude: 127.0))
    )

    func execute(coordinate: Coordinate) async throws -> Place {
        try result.get()
    }
}

private struct StoreError: Error {}
private struct SignUpError: Error {}
private struct GeocodeError: Error {}

struct DefaultSignInUseCaseTests {
    private let recorder = SignInRecorder()

    private func makeSUT(
        social: StubSocialLoginService? = nil,
        repository: StubAuthRepository? = nil,
        store: StubSessionStore? = nil,
        pushToken: String? = nil,
        location: StubGetCurrentLocationUseCase = StubGetCurrentLocationUseCase(),
        geocode: StubReverseGeocodeUseCase = StubReverseGeocodeUseCase()
    ) -> DefaultSignInUseCase {
        DefaultSignInUseCase(
            socialLoginService: social ?? StubSocialLoginService(recorder: recorder),
            authRepository: repository ?? StubAuthRepository(recorder: recorder),
            sessionStore: store ?? StubSessionStore(recorder: recorder),
            pushTokenProvider: StubPushTokenProvider(token: pushToken),
            getCurrentLocationUseCase: location,
            reverseGeocodeUseCase: geocode
        )
    }

    @Test
    func execute_registered_runsAuthorizeCheckLoginStoreInOrder() async throws {
        let sut = makeSUT(pushToken: "FCM")

        try await sut.execute(provider: .kakao)

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

        try await sut.execute(provider: .apple)

        #expect(recorder.count(of: "login(fcm:nil)") == 1)
    }

    /// 미가입이면 자동으로 최소 가입한다 — 현재 좌표 + 역지오코딩 주소 + 기본 알림 빈도.
    @Test
    func execute_notRegistered_signsUpWithLocationFormThenStores() async throws {
        let sut = makeSUT(
            repository: StubAuthRepository(recorder: recorder, exists: false),
            pushToken: "FCM"
        )

        try await sut.execute(provider: .kakao)

        #expect(recorder.log == [
            "authorize",
            "check(SOCIAL)",
            "signUp(addr:서울 어딘가 1-2/lat:37.5/freq:[1, 10]/name:/fcm:FCM)",
            "store(SA/SR)",
        ])
    }

    /// 위치 실패(권한 거부 등) → 레거시 실측 폴백(address ""·좌표 (0,0))으로 가입한다.
    @Test
    func execute_notRegistered_locationFailure_fallsBackToMinimalForm() async throws {
        let sut = makeSUT(
            repository: StubAuthRepository(recorder: recorder, exists: false),
            location: StubGetCurrentLocationUseCase(result: .failure(.permissionDenied))
        )

        try await sut.execute(provider: .kakao)

        #expect(recorder.count(of: "signUp(addr:/lat:0.0/freq:[1, 10]/name:/fcm:nil)") == 1)
    }

    /// 역지오코딩만 실패하면 좌표는 유지하고 주소만 빈 문자열로 강등한다.
    @Test
    func execute_notRegistered_geocodeFailure_keepsCoordinateWithEmptyAddress() async throws {
        let sut = makeSUT(
            repository: StubAuthRepository(recorder: recorder, exists: false),
            geocode: StubReverseGeocodeUseCase(result: .failure(GeocodeError()))
        )

        try await sut.execute(provider: .kakao)

        #expect(recorder.count(of: "signUp(addr:/lat:37.5/freq:[1, 10]/name:/fcm:nil)") == 1)
    }

    /// 가입 실패는 그대로 전파되고 세션은 채택되지 않는다.
    @Test
    func execute_signUpFailure_propagatesWithoutStore() async {
        let sut = makeSUT(
            repository: StubAuthRepository(
                recorder: recorder, exists: false, signUpError: SignUpError()
            )
        )

        await #expect(throws: SignUpError.self) {
            try await sut.execute(provider: .kakao)
        }

        #expect(recorder.count(of: "store(SA/SR)") == 0)
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
