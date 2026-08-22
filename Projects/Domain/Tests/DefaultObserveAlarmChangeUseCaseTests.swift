@testable import Domain
import Foundation
import Testing

private struct StubAlarmChangeEvents: AlarmChangeEvents {
    let handler: @Sendable () -> AsyncStream<AlarmChangeVerdict>
    func changes() -> AsyncStream<AlarmChangeVerdict> { handler() }
}

struct DefaultObserveAlarmChangeUseCaseTests {
    @Test
    func execute_forwardsPortStream() async {
        let sut = DefaultObserveAlarmChangeUseCase(
            events: StubAlarmChangeEvents {
                AsyncStream { continuation in
                    continuation.yield(.delayed(by: 600))
                    continuation.yield(.sessionEnded)
                    continuation.finish()
                }
            }
        )

        var received: [AlarmChangeVerdict] = []
        for await verdict in sut.execute() {
            received.append(verdict)
        }

        #expect(received == [.delayed(by: 600), .sessionEnded])
    }
}
