import CoreAuth
import Domain

/// Domain의 세션 종료 포트를 CoreAuth의 AuthSessionManager로 배선한다.
/// 두 경로 모두 sessionExpired yield를 거치므로 로그인 복귀 라우팅은
/// AppCoordinator의 기존 만료 관찰이 그대로 처리한다.
struct AuthSessionEndingAdapter: SessionEnding {
    let sessionManager: AuthSessionManager

    func endSession() async {
        await sessionManager.signOut()
    }

    func invalidateLocalSession() async {
        await sessionManager.invalidateSession()
    }
}
