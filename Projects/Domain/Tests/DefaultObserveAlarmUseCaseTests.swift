@testable import Domain
import Foundation
import Testing

private struct StubAlarmSyncEvents: AlarmSyncEvents {
    let handler: @Sendable () -> AsyncStream<AlarmInfo>
    func updates() -> AsyncStream<AlarmInfo> { handler() }
}

struct DefaultObserveAlarmUseCaseTests {
    @Test
    func execute_forwardsPortStream() async {
        let info = AlarmInfo(
            lastRouteId: "r1",
            departureTime: Date(timeIntervalSince1970: 1_755_800_000),
            updatedAt: nil,
            isReal: true
        )
        let sut = DefaultObserveAlarmUseCase(
            events: StubAlarmSyncEvents {
                AsyncStream { continuation in
                    continuation.yield(info)
                    continuation.finish()
                }
            }
        )

        var received: [AlarmInfo] = []
        for await update in sut.execute() {
            received.append(update)
        }

        #expect(received == [info])
    }
}
