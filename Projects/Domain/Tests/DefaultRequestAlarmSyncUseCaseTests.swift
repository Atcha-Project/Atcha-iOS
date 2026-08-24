@testable import Domain
import Foundation
import Testing

private actor SpyAlarmSyncRequesting: AlarmSyncRequesting {
    private(set) var syncNowCount = 0
    func syncNow() async { syncNowCount += 1 }
}

struct DefaultRequestAlarmSyncUseCaseTests {
    @Test
    func execute_forwardsToPortOncePerCall() async {
        let spy = SpyAlarmSyncRequesting()
        let sut = DefaultRequestAlarmSyncUseCase(requesting: spy)

        await sut.execute()
        await sut.execute()

        // 합류·중복 억제는 포트 구현(AlarmSyncService inFlight)의 몫 — UseCase는 위임만.
        #expect(await spy.syncNowCount == 2)
    }
}
