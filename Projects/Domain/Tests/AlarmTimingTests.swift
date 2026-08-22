@testable import Domain
import Foundation
import Testing

struct AlarmTimingTests {
    @Test
    func alarmFireDate_isDepartureMinusBuffer() {
        let departure = Date(timeIntervalSince1970: 1_000)
        #expect(AlarmTiming.alarmFireDate(departureTime: departure) == Date(timeIntervalSince1970: 820))
    }

    @Test
    func buffer_isFixedThreeMinutes() {
        #expect(AlarmTiming.bufferSeconds == 180)
    }
}
