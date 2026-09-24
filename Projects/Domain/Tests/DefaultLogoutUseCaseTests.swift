@testable import Domain
import Synchronization
import Testing

private final class SessionEndingSpy: SessionEnding, Sendable {
    private let events = Mutex<[String]>([])
    var log: [String] { events.withLock { $0 } }

    func endSession() async { events.withLock { $0.append("endSession") } }
    func invalidateLocalSession() async { events.withLock { $0.append("invalidate") } }
    func append(_ event: String) { events.withLock { $0.append(event) } }
}

private struct TeardownSpy: AlarmSessionTeardown {
    let spy: SessionEndingSpy
    func tearDown(cancelOnServer: Bool) async { spy.append("tearDown(\(cancelOnServer))") }
}

struct DefaultLogoutUseCaseTests {
    @Test
    func execute_endsSession() async {
        let spy = SessionEndingSpy()
        let sut = DefaultLogoutUseCase(sessionEnding: spy)

        await sut.execute()

        #expect(spy.log == ["endSession"])
    }

    /// 서버 알람 취소는 토큰이 살아 있을 때만 가능 — 정리가 세션 종료보다 먼저여야 한다.
    @Test
    func execute_tearsDownAlarmsBeforeEndingSession() async {
        let spy = SessionEndingSpy()
        let sut = DefaultLogoutUseCase(sessionEnding: spy, alarmTeardown: TeardownSpy(spy: spy))

        await sut.execute()

        #expect(spy.log == ["tearDown(true)", "endSession"])
    }
}
