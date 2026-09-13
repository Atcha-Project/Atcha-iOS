public protocol LogoutUseCase: Sendable {
    /// 서버 로그아웃은 베스트 에포트 — 실패해도 로컬 세션은 끝난다(throws 없음).
    func execute() async
}

public struct DefaultLogoutUseCase: LogoutUseCase {
    private let sessionEnding: any SessionEnding

    public init(sessionEnding: any SessionEnding) {
        self.sessionEnding = sessionEnding
    }

    public func execute() async {
        await sessionEnding.endSession()
    }
}
