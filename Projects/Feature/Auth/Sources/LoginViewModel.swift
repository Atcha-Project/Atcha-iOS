import Domain
import Foundation

@MainActor
final class LoginViewModel {
    enum State: Equatable {
        case idle
        /// 어느 제공자로 진행 중인지 — 화면은 양 버튼을 잠근다(중복 탭 방지).
        case loading(SocialLoginProvider)
    }

    /// 원샷 안내 — 상태와 분리한다(Home의 ToastEvent 패턴).
    enum Event: Equatable {
        case showFailureToast(message: String)
    }

    static let failureMessage = "로그인에 실패했어요. 잠시 후 다시 시도해주세요."

    var onStateChange: ((State) -> Void)?
    var onEvent: ((Event) -> Void)?
    /// 세션 채택까지 완료된 뒤에만 불린다 — 코디네이터가 플로우를 닫는 신호.
    var onAuthenticated: (() -> Void)?

    private(set) var state: State = .idle {
        didSet { onStateChange?(state) }
    }

    private let signInUseCase: any SignInUseCase
    private var signInTask: Task<Void, Never>?

    init(signInUseCase: any SignInUseCase) {
        self.signInUseCase = signInUseCase
    }

    deinit {
        signInTask?.cancel()
    }

    func kakaoTapped() {
        signIn(provider: .kakao)
    }

    func appleTapped() {
        signIn(provider: .apple)
    }

    private func signIn(provider: SocialLoginProvider) {
        guard state == .idle else { return }
        state = .loading(provider)
        signInTask = Task { [weak self] in
            guard let self else { return }
            do {
                // 미가입 계정은 UseCase가 최소 가입까지 수행한다 — 성공은 곧 세션 채택 완료.
                try await self.signInUseCase.execute(provider: provider)
                guard !Task.isCancelled else { return }
                // 성공 시 idle 복귀 없이 바로 닫는다 — 버튼이 다시 살아나며
                // 깜빡이는 프레임을 만들지 않는다.
                self.onAuthenticated?()
            } catch SocialLoginError.cancelled {
                // 사용자가 소셜 UI를 스스로 닫음 — 에러 표출 없이 재시도 대기.
                guard !Task.isCancelled else { return }
                self.state = .idle
            } catch {
                guard !Task.isCancelled else { return }
                self.state = .idle
                self.onEvent?(.showFailureToast(message: Self.failureMessage))
            }
        }
    }
}
