/// 계정 세션 종료(로그아웃·탈퇴·강제 만료) 시 알람 세션 정리 포트 — 구현은 App 어댑터.
/// 레거시는 로그아웃 후에도 알람·노티가 살아 있어 로그인 화면에서 알람이 울렸다(이식 금지 버그).
/// 멱등이어야 한다 — 로그아웃 경로와 만료 라우팅 경로가 연달아 부를 수 있다.
public protocol AlarmSessionTeardown: Sendable {
    /// 로컬 알람·LA·스냅샷·동기화 상태를 비운다. cancelOnServer=true면 서버 알람 취소를
    /// 베스트 에포트로 먼저 시도한다 — 토큰이 아직 살아 있는 로그아웃 경로에서만 의미가 있다.
    func tearDown(cancelOnServer: Bool) async
}
