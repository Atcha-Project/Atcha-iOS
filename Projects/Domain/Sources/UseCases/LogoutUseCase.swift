public protocol LogoutUseCase: Sendable {
    /// 서버 로그아웃은 베스트 에포트 — 실패해도 로컬 세션은 끝난다(throws 없음).
    func execute() async
}

public struct DefaultLogoutUseCase: LogoutUseCase {
    private let sessionEnding: any SessionEnding
    /// nil이면 알람 정리 없이 동작한다(Example·테스트 호환).
    private let alarmTeardown: (any AlarmSessionTeardown)?

    public init(sessionEnding: any SessionEnding, alarmTeardown: (any AlarmSessionTeardown)? = nil) {
        self.sessionEnding = sessionEnding
        self.alarmTeardown = alarmTeardown
    }

    public func execute() async {
        // 서버 알람 취소는 토큰이 살아 있을 때만 가능하다 — 세션 종료보다 반드시 먼저.
        await alarmTeardown?.tearDown(cancelOnServer: true)
        await sessionEnding.endSession()
    }
}
