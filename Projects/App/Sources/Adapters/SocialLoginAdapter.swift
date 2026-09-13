import AuthenticationServices
import Domain
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser
import UIKit

/// 소셜 SDK를 아는 곳은 이 어댑터뿐(외부 라이브러리 앱 타겟 전용 링크 규약).
/// 레거시 `LoginUseCaseImpl`의 delegate 이중 보관·`self.delegate!`·`view.window!`
/// force unwrap을 제거한 async 래핑 — 진행 중 continuation은 take()(nil 교체 후 사용)로
/// 이중 resume을 차단한다.
@MainActor
final class SocialLoginAdapter: NSObject, SocialLoginService {
    // 진행 중 Apple 플로우 — 어댑터가 delegate로 살아 있는 동안 controller도 함께 보관.
    private var appleContinuation: CheckedContinuation<SocialCredential, any Error>?
    private var appleController: ASAuthorizationController?

    func authorize(provider: SocialLoginProvider) async throws -> SocialCredential {
        switch provider {
        case .kakao: try await authorizeKakao()
        case .apple: try await authorizeApple()
        }
    }

    // MARK: - Kakao

    private func authorizeKakao() async throws -> SocialCredential {
        // initSDK가 안 된 상태(키 미주입)에서 UserApi를 부르면 SDK가 fatal — 선차단.
        guard KakaoConfig.appKey != nil else { throw SocialLoginError.providerUnavailable }
        let accessToken: String = try await withCheckedThrowingContinuation { continuation in
            let completion: (OAuthToken?, (any Error)?) -> Void = { oauthToken, error in
                if let error {
                    continuation.resume(throwing: Self.mapKakaoError(error))
                } else if let accessToken = oauthToken?.accessToken {
                    continuation.resume(returning: accessToken)
                } else {
                    continuation.resume(throwing: SocialLoginError.failed)
                }
            }
            // 카카오톡 앱 설치 시 앱 전환, 아니면 계정 웹뷰 — 레거시 분기 그대로.
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk(completion: completion)
            } else {
                UserApi.shared.loginWithKakaoAccount(completion: completion)
            }
        }
        return SocialCredential(provider: .kakao, accessToken: accessToken)
    }

    private static func mapKakaoError(_ error: any Error) -> any Error {
        // 사용자 취소는 조용한 idle 복귀 대상 — 그 외는 실패 토스트로 표면화.
        if let sdkError = error as? SdkError,
           case let .ClientFailed(reason, _) = sdkError,
           reason == .Cancelled {
            return SocialLoginError.cancelled
        }
        return error
    }

    // MARK: - Apple

    private func authorizeApple() async throws -> SocialCredential {
        // ViewModel의 로딩 가드가 1차 방어지만, 플로우 단일성은 여기서도 보장한다.
        guard appleContinuation == nil else { throw SocialLoginError.failed }
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        appleController = controller
        return try await withCheckedThrowingContinuation { continuation in
            appleContinuation = continuation
            controller.performRequests()
        }
    }

    private func takeAppleContinuation() -> CheckedContinuation<SocialCredential, any Error>? {
        defer {
            appleContinuation = nil
            appleController = nil
        }
        return appleContinuation
    }
}

extension SocialLoginAdapter: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let continuation = takeAppleContinuation() else { return }
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8)
        else {
            continuation.resume(throwing: SocialLoginError.failed)
            return
        }
        continuation.resume(
            returning: SocialCredential(provider: .apple, accessToken: identityToken)
        )
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {
        guard let continuation = takeAppleContinuation() else { return }
        if let authorizationError = error as? ASAuthorizationError,
           authorizationError.code == .canceled {
            continuation.resume(throwing: SocialLoginError.cancelled)
        } else {
            continuation.resume(throwing: error)
        }
    }
}

extension SocialLoginAdapter: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 레거시의 `view.window!` 대체 — 호출 시점의 활성 씬 key window를 해석하고,
        // 끝내 없으면 빈 앵커로 강제 크래시만 피한다(시트가 안 뜰 뿐).
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        return scene?.keyWindow ?? scene?.windows.first ?? ASPresentationAnchor()
    }
}
