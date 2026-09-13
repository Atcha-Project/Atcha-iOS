@testable import Domain
import Synchronization
import Testing

private final class SessionEndingSpy: SessionEnding, Sendable {
    private let events = Mutex<[String]>([])
    var log: [String] { events.withLock { $0 } }

    func endSession() async { events.withLock { $0.append("endSession") } }
    func invalidateLocalSession() async { events.withLock { $0.append("invalidate") } }
}

struct DefaultLogoutUseCaseTests {
    @Test
    func execute_endsSession() async {
        let spy = SessionEndingSpy()
        let sut = DefaultLogoutUseCase(sessionEnding: spy)

        await sut.execute()

        #expect(spy.log == ["endSession"])
    }
}
