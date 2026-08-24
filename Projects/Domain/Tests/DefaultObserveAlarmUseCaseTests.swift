@testable import Domain
import Foundation
import Testing

private struct StubAlarmSyncEvents: AlarmSyncEvents {
    let handler: @Sendable () -> AsyncStream<AlarmSyncUpdate>
    func updates() -> AsyncStream<AlarmSyncUpdate> { handler() }
}

struct DefaultObserveAlarmUseCaseTests {
    @Test
    func execute_forwardsPortStream() async {
        let update = AlarmSyncUpdate(
            info: AlarmInfo(
                lastRouteId: "r1",
                departureTime: Date(timeIntervalSince1970: 1_755_800_000),
                updatedAt: nil,
                isReal: true
            ),
            // 확인 시각이 함께 흘러야 한다 — 신선도 스탬프의 원천(Phase 16).
            checkedAt: Date(timeIntervalSince1970: 1_755_790_000)
        )
        let sut = DefaultObserveAlarmUseCase(
            events: StubAlarmSyncEvents {
                AsyncStream { continuation in
                    continuation.yield(update)
                    continuation.finish()
                }
            }
        )

        var received: [AlarmSyncUpdate] = []
        for await value in sut.execute() {
            received.append(value)
        }

        #expect(received == [update])
    }
}
