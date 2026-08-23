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

    // MARK: - 클라 자체 만료 (Phase 13)

    @Test
    func expiryGrace_isFixedSixtySeconds() {
        #expect(AlarmTiming.expiryGraceSeconds == 60)
    }

    @Test
    func isSessionExpired_boundaries() {
        let departure = Date(timeIntervalSince1970: 1_000)
        // 출발 전·유예 안은 만료가 아니다.
        #expect(!AlarmTiming.isSessionExpired(
            departureTime: departure, now: departure.addingTimeInterval(-1)
        ))
        #expect(!AlarmTiming.isSessionExpired(departureTime: departure, now: departure))
        #expect(!AlarmTiming.isSessionExpired(
            departureTime: departure, now: departure.addingTimeInterval(59)
        ))
        // 경계(정확히 +60초)부터 만료 — 홈 배너 2단계(now < 출발+유예)와 상보적이다.
        #expect(AlarmTiming.isSessionExpired(
            departureTime: departure, now: departure.addingTimeInterval(60)
        ))
        #expect(AlarmTiming.isSessionExpired(
            departureTime: departure, now: departure.addingTimeInterval(61)
        ))
    }

    @Test
    func isSessionExpired_acrossMidnight_usesAbsoluteDateArithmetic() {
        // 자정 경계: 23:59:30 출발 → 익일 00:00:20은 벽시계로 "이른 시각"이지만
        // 절대 시간으로 +50초 — 아직 유예 안이다.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let departure = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 23, hour: 23, minute: 59, second: 30)
        )!
        let beforeGrace = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 24, hour: 0, minute: 0, second: 20)
        )!
        let afterGrace = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 24, hour: 0, minute: 0, second: 31)
        )!

        #expect(!AlarmTiming.isSessionExpired(departureTime: departure, now: beforeGrace))
        #expect(AlarmTiming.isSessionExpired(departureTime: departure, now: afterGrace))
    }
}
