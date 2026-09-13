@testable import AuthFeature
import Domain
import Foundation
import Testing

@MainActor
private final class StubSignInUseCase: SignInUseCase {
    private(set) var executeCallCount = 0
    private(set) var providers: [SocialLoginProvider] = []
    private var result: Result<SignInOutcome, any Error>
    private let suspends: Bool
    private var continuation: CheckedContinuation<SignInOutcome, any Error>?

    init(result: Result<SignInOutcome, any Error> = .success(.success), suspends: Bool = false) {
        self.result = result
        self.suspends = suspends
    }

    func execute(provider: SocialLoginProvider) async throws -> SignInOutcome {
        executeCallCount += 1
        providers.append(provider)
        if suspends {
            return try await withCheckedThrowingContinuation { continuation = $0 }
        }
        return try result.get()
    }

    func resume(with outcome: SignInOutcome) {
        continuation?.resume(returning: outcome)
        continuation = nil
    }
}

@MainActor
private final class Recorder {
    private(set) var states: [LoginViewModel.State] = []
    private(set) var events: [LoginViewModel.Event] = []
    private(set) var authenticatedCount = 0

    func attach(to viewModel: LoginViewModel) {
        viewModel.onStateChange = { [weak self] state in self?.states.append(state) }
        viewModel.onEvent = { [weak self] event in self?.events.append(event) }
        viewModel.onAuthenticated = { [weak self] in self?.authenticatedCount += 1 }
    }

    // Home 템플릿의 드레인 패턴: 스텁이 즉시 resolve하므로 yield로 충분하다.
    func waitUntil(_ predicate: () -> Bool) async {
        while !predicate() {
            await Task.yield()
        }
    }
}

private struct StubError: Error {}

@MainActor
struct LoginViewModelTests {
    @Test
    func kakaoTapped_success_callsOnAuthenticatedWithoutIdleFlicker() async {
        let useCase = StubSignInUseCase(result: .success(.success))
        let sut = LoginViewModel(signInUseCase: useCase)
        let recorder = Recorder()
        recorder.attach(to: sut)

        sut.kakaoTapped()
        await recorder.waitUntil { recorder.authenticatedCount == 1 }

        #expect(useCase.providers == [.kakao])
        // 성공 시 idle 복귀 없이 바로 닫힌다 — 버튼 재활성 프레임 없음.
        #expect(recorder.states == [.loading(.kakao)])
        #expect(recorder.events.isEmpty)
    }

    @Test
    func appleTapped_passesAppleProvider() async {
        let useCase = StubSignInUseCase(result: .success(.success))
        let sut = LoginViewModel(signInUseCase: useCase)
        let recorder = Recorder()
        recorder.attach(to: sut)

        sut.appleTapped()
        await recorder.waitUntil { recorder.authenticatedCount == 1 }

        #expect(useCase.providers == [.apple])
    }

    @Test
    func tapped_needsSignUp_returnsIdleAndEmitsNotice() async {
        let useCase = StubSignInUseCase(result: .success(.needsSignUp))
        let sut = LoginViewModel(signInUseCase: useCase)
        let recorder = Recorder()
        recorder.attach(to: sut)

        sut.kakaoTapped()
        await recorder.waitUntil { recorder.states.last == .idle }

        #expect(recorder.events == [.showSignUpNotice])
        #expect(recorder.authenticatedCount == 0)
    }

    @Test
    func tapped_socialCancelled_returnsIdleSilently() async {
        let useCase = StubSignInUseCase(result: .failure(SocialLoginError.cancelled))
        let sut = LoginViewModel(signInUseCase: useCase)
        let recorder = Recorder()
        recorder.attach(to: sut)

        sut.kakaoTapped()
        await recorder.waitUntil { recorder.states.last == .idle }

        #expect(recorder.events.isEmpty)
        #expect(recorder.authenticatedCount == 0)
    }

    @Test
    func tapped_failure_returnsIdleAndEmitsFailureToast() async {
        let useCase = StubSignInUseCase(result: .failure(StubError()))
        let sut = LoginViewModel(signInUseCase: useCase)
        let recorder = Recorder()
        recorder.attach(to: sut)

        sut.appleTapped()
        await recorder.waitUntil { recorder.states.last == .idle }

        #expect(recorder.events == [.showFailureToast(message: LoginViewModel.failureMessage)])
        #expect(recorder.authenticatedCount == 0)
    }

    /// 로딩 중 중복 탭은 무시된다 — 소셜 UI 이중 기동 방지.
    @Test
    func tapped_whileLoading_ignoresSecondTap() async {
        let useCase = StubSignInUseCase(suspends: true)
        let sut = LoginViewModel(signInUseCase: useCase)
        let recorder = Recorder()
        recorder.attach(to: sut)

        sut.kakaoTapped()
        await recorder.waitUntil { useCase.executeCallCount == 1 }
        sut.appleTapped()

        #expect(useCase.executeCallCount == 1)
        #expect(recorder.states == [.loading(.kakao)])

        useCase.resume(with: .success)
        await recorder.waitUntil { recorder.authenticatedCount == 1 }
    }
}
