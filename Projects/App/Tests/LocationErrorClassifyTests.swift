@testable import AtchaV2
import Domain
import Testing

/// CLLocationUpdate 거부 플래그 → LocationError 매핑(Phase 17) — 사유별 안내 분기의 원천.
@MainActor
struct LocationErrorClassifyTests {
    @Test
    func eachFlag_mapsToItsOwnCase() {
        #expect(CoreLocationServiceAdapter.classify(
            denied: true, deniedGlobally: false, restricted: false
        ) == .permissionDenied)
        #expect(CoreLocationServiceAdapter.classify(
            denied: false, deniedGlobally: true, restricted: false
        ) == .servicesDisabled)
        #expect(CoreLocationServiceAdapter.classify(
            denied: false, deniedGlobally: false, restricted: true
        ) == .restricted)
    }

    @Test
    func noFlags_meansStillInProgress() {
        #expect(CoreLocationServiceAdapter.classify(
            denied: false, deniedGlobally: false, restricted: false
        ) == nil)
    }

    @Test
    func priority_narrowerRecoveryPathWins() {
        // restricted > 전역 OFF > 앱 권한 거부 — 복합 플래그에선 더 좁은 회복 경로가 이긴다.
        #expect(CoreLocationServiceAdapter.classify(
            denied: true, deniedGlobally: true, restricted: true
        ) == .restricted)
        #expect(CoreLocationServiceAdapter.classify(
            denied: true, deniedGlobally: true, restricted: false
        ) == .servicesDisabled)
    }
}
