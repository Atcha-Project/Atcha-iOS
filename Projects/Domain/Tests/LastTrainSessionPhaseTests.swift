@testable import Domain
import Testing

struct LastTrainSessionPhaseTests {
    @Test
    func rawValues_matchCoreLiveActivityWireContract() {
        // 어댑터는 rawValue로 CoreLiveActivity `LastTrainSessionStatus`에 매핑한다 —
        // 케이스명 변경은 리팩터가 아니라 wire 계약 파손이다 (Phase 13: departed 추가).
        #expect(LastTrainSessionPhase.active.rawValue == "active")
        #expect(LastTrainSessionPhase.departed.rawValue == "departed")
        #expect(LastTrainSessionPhase.missed.rawValue == "missed")
        #expect(LastTrainSessionPhase.serviceEnded.rawValue == "serviceEnded")
    }
}
