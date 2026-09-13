/// 세션 종료 포트 — 어댑터는 App에서 `AuthSessionManager`로 배선.
public protocol SessionEnding: Sendable {
    /// 로그아웃: 서버 `/auth/logout`은 베스트 에포트(실패 무시)로 호출하고,
    /// 로컬 토큰 정리와 세션 만료 라우팅(로그인 복귀)을 항상 진행한다.
    func endSession() async
    /// 탈퇴 후 정리: 서버 토큰은 이미 무효이므로 로컬 정리 + 만료 라우팅만.
    func invalidateLocalSession() async
}
