@testable import Domain
import Foundation
import Testing

private func makeInfo(departureTime: Date?) -> AlarmInfo {
    AlarmInfo(lastRouteId: "route-1", departureTime: departureTime, updatedAt: nil, isReal: true)
}

/// KST 절대 시각 헬퍼 — 자정 경계 테스트가 벽시계가 아닌 절대 Date 연산임을 보장한다.
private func kst(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
    let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
    return calendar.date(from: components)!
}

struct DefaultEvaluateAlarmChangeUseCaseTests {
    private let sut = DefaultEvaluateAlarmChangeUseCase()
    private let now = Date(timeIntervalSince1970: 10_000)

    @Test
    func execute_sameDeparture_unchanged() {
        let departure = Date(timeIntervalSince1970: 10_600)
        let verdict = sut.execute(
            previous: makeInfo(departureTime: departure),
            latest: makeInfo(departureTime: departure),
            now: now
        )
        #expect(verdict == .unchanged)

        // 초 단위 동일(서브초 오차)도 변경이 아니다.
        let subSecond = sut.execute(
            previous: makeInfo(departureTime: departure),
            latest: makeInfo(departureTime: departure.addingTimeInterval(0.4)),
            now: now
        )
        #expect(subSecond == .unchanged)
    }

    @Test
    func execute_advancedFiveMinutes_latestStillFuture_actionableAlert() {
        let verdict = sut.execute(
            previous: makeInfo(departureTime: Date(timeIntervalSince1970: 10_900)),
            latest: makeInfo(departureTime: Date(timeIntervalSince1970: 10_600)),
            now: now
        )
        #expect(verdict == .advanced(by: 300, actionable: true))
    }

    @Test
    func execute_advanced_latestAlreadyPast_notActionable() {
        let verdict = sut.execute(
            previous: makeInfo(departureTime: Date(timeIntervalSince1970: 10_600)),
            latest: makeInfo(departureTime: Date(timeIntervalSince1970: 9_700)),
            now: now
        )
        #expect(verdict == .advanced(by: 900, actionable: false))

        // 경계: latest == now도 이미 못 탄 것으로 본다 (미래여야 actionable).
        let boundary = sut.execute(
            previous: makeInfo(departureTime: Date(timeIntervalSince1970: 10_600)),
            latest: makeInfo(departureTime: now),
            now: now
        )
        #expect(boundary == .advanced(by: 600, actionable: false))
    }

    @Test
    func execute_delayedTenMinutes_delayed() {
        let verdict = sut.execute(
            previous: makeInfo(departureTime: Date(timeIntervalSince1970: 10_600)),
            latest: makeInfo(departureTime: Date(timeIntervalSince1970: 11_200)),
            now: now
        )
        #expect(verdict == .delayed(by: 600))
    }

    @Test
    func execute_latestDepartureNil_sessionEnded() {
        let verdict = sut.execute(
            previous: makeInfo(departureTime: Date(timeIntervalSince1970: 10_600)),
            latest: makeInfo(departureTime: nil),
            now: now
        )
        #expect(verdict == .sessionEnded)
    }

    @Test
    func execute_previousDepartureNil_firstObservation_unchanged() {
        let verdict = sut.execute(
            previous: makeInfo(departureTime: nil),
            latest: makeInfo(departureTime: Date(timeIntervalSince1970: 10_600)),
            now: now
        )
        #expect(verdict == .unchanged)
    }

    @Test
    func execute_delayedAcrossMidnight_absoluteDateArithmetic() {
        // 23:40 → 익일 00:10: 벽시계로는 "이른 시각"이지만 절대 시간으로는 30분 늦춰짐.
        let verdict = sut.execute(
            previous: makeInfo(departureTime: kst(2026, 8, 22, 23, 40)),
            latest: makeInfo(departureTime: kst(2026, 8, 23, 0, 10)),
            now: kst(2026, 8, 22, 23, 0)
        )
        #expect(verdict == .delayed(by: 1_800))
    }

    @Test
    func execute_advancedAcrossMidnight_absoluteDateArithmetic() {
        // 익일 00:10 → 당일 23:40: 절대 시간으로 30분 당겨짐, 아직 미래라 actionable.
        let verdict = sut.execute(
            previous: makeInfo(departureTime: kst(2026, 8, 23, 0, 10)),
            latest: makeInfo(departureTime: kst(2026, 8, 22, 23, 40)),
            now: kst(2026, 8, 22, 23, 0)
        )
        #expect(verdict == .advanced(by: 1_800, actionable: true))
    }
}
