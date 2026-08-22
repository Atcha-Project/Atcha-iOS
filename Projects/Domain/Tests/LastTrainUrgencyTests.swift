@testable import Domain
import Foundation
import Testing

struct LastTrainUrgencyTests {
    // 임계는 디자이너 확정 전 제안값: ≤10분 imminent, ≤30분 caution (경계 포함).

    @Test
    func forTimeRemaining_over30Minutes_isRelaxed() {
        #expect(LastTrainUrgency.forTimeRemaining(3_600) == .relaxed)
        // 30분 경계 바로 위 — caution이 아니다.
        #expect(LastTrainUrgency.forTimeRemaining(1_801) == .relaxed)
    }

    @Test
    func forTimeRemaining_exactly30Minutes_isCaution() {
        #expect(LastTrainUrgency.forTimeRemaining(1_800) == .caution)
    }

    @Test
    func forTimeRemaining_between10And30Minutes_isCaution() {
        #expect(LastTrainUrgency.forTimeRemaining(601) == .caution)
    }

    @Test
    func forTimeRemaining_exactly10Minutes_isImminent() {
        // HomeViewModel.makeBanner의 "10분 이하 긴박"과 같은 경계(600초 포함).
        #expect(LastTrainUrgency.forTimeRemaining(600) == .imminent)
    }

    @Test
    func forTimeRemaining_zero_isImminent() {
        #expect(LastTrainUrgency.forTimeRemaining(0) == .imminent)
    }

    @Test
    func forTimeRemaining_negative_isImminent() {
        // 이미 지난 시각(막차 출발 후)도 imminent — relaxed로 되돌아가면 안 된다.
        #expect(LastTrainUrgency.forTimeRemaining(-60) == .imminent)
    }
}
