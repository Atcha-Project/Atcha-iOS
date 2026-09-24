import Domain
import Foundation
@testable import HomeFeature
import Testing

/// 세션 상태 전이의 표 테스트 — 스텁 0개, ViewModel 0개.
///
/// 이 테스트들이 지키는 것은 "불법 조합이 표현 불가능하다"는 성질이다. 예전 평평한
/// State에서는 이 성질을 **메서드가 손으로** 지켰고, 한 곳만 빠뜨려도 화면이 어긋났다.
struct HomeSessionStateTests {
    /// 카드 내용은 이 테스트의 관심사가 아니다 — 경로 id가 어디에 붙어 다니는지만 본다.
    private func makeCard(_ id: String) -> HomeSessionState.Card {
        let route = LastRoute(
            id: id,
            departureTime: Date(timeIntervalSince1970: 1_700_000_000),
            totalTime: 3600, totalWalkTime: 600, transferCount: 1,
            totalDistance: 12000, totalWalkDistance: 800,
            legs: []
        )
        return HomeSessionState.Card(
            routeId: id, view: RouteCardViewData(entity: route, now: Date(timeIntervalSince1970: 1_699_990_000))
        )
    }

    private func makeRegistration(
        _ id: String, banner: HomeViewModel.BannerViewData? = nil, syncedAt: Date? = nil
    ) -> HomeSessionState.Registration {
        HomeSessionState.Registration(routeId: id, banner: banner, syncedAt: syncedAt)
    }

    private let banner = HomeViewModel.BannerViewData(text: "출발까지 10분", urgency: .relaxed)

    // MARK: - 알람 버튼

    @Test
    func alarmButton_empty_isHidden() {
        #expect(HomeSessionState.empty.alarmButton == .hidden)
    }

    @Test
    func alarmButton_cardOnly_isRegister() {
        #expect(HomeSessionState.card(makeCard("A"), busy: false).alarmButton == .register)
    }

    /// 지난 막차에는 등록 버튼을 두지 않는다 — 누르면 tooLate로 실패할 뿐이다.
    @Test
    func alarmButton_past_isHidden() {
        #expect(HomeSessionState.past(makeCard("A")).alarmButton == .hidden)
    }

    @Test
    func alarmButton_armedOnSameRoute_isCancel() {
        let session = HomeSessionState.armed(makeRegistration("A"), card: makeCard("A"), busy: false)
        #expect(session.alarmButton == .cancel)
    }

    /// 등록된 채로 **다른** 경로를 고른 상태 — 그 카드의 알람은 아직 없으니 "등록"이다.
    @Test
    func alarmButton_armedWithDifferentSelection_isRegister() {
        let session = HomeSessionState.armed(makeRegistration("A"), card: makeCard("B"), busy: false)
        #expect(session.alarmButton == .register)
    }

    /// 재실행 복원 중(상세 미도착) — 카드 없이 해제만 가능하다.
    @Test
    func alarmButton_armedWithoutCard_isCancel() {
        #expect(HomeSessionState.armed(makeRegistration("A"), card: nil, busy: false).alarmButton == .cancel)
    }

    // MARK: - 전이

    /// 새 경로 선택은 배너를 무효화하되 **등록은 살려 둔다** — 해제하지 않고 다른 경로를
    /// 보는 것은 정상 흐름이다.
    @Test
    func selecting_whileArmed_clearsBannerButKeepsRegistration() {
        let session = HomeSessionState
            .armed(makeRegistration("A", banner: banner, syncedAt: .init()), card: makeCard("A"), busy: false)
            .selecting(makeCard("B"))

        #expect(session.registration?.routeId == "A")
        #expect(session.registration?.banner == nil)
        #expect(session.registration?.syncedAt != nil)
        #expect(session.card?.routeId == "B")
        #expect(session.alarmButton == .register)
    }

    /// 해제는 등록·배너·스탬프·busy를 **한 번에** 없앤다. 예전에는 다섯 필드를 따로
    /// 고쳐야 했고, 하나씩 고치면 didSet이 중간 상태를 화면으로 내보냈다.
    @Test
    func disarmed_dropsRegistrationAndKeepsCard() {
        let session = HomeSessionState
            .armed(makeRegistration("A", banner: banner, syncedAt: .init()), card: makeCard("A"), busy: true)
            .disarmed()

        #expect(session.registration == nil)
        #expect(session.card?.routeId == "A")
        #expect(!session.isBusy)
        #expect(session.alarmButton == .register)
    }

    @Test
    func disarmed_withoutCard_becomesEmpty() {
        #expect(HomeSessionState.armed(makeRegistration("A"), card: nil, busy: false).disarmed() == .empty)
    }

    /// **배너는 등록 없이 존재할 수 없다.** 평평한 State에서는 이 조합이 표현 가능했다.
    @Test
    func withBanner_withoutRegistration_isIgnored() {
        #expect(HomeSessionState.card(makeCard("A"), busy: false).withBanner(banner).registration == nil)
        #expect(HomeSessionState.empty.withBanner(banner) == .empty)
        #expect(HomeSessionState.past(makeCard("A")).withBanner(banner).registration == nil)
    }

    /// **아무것도 없는데 진행 중일 수 없다.** 예전에는 `isAlarmBusy`가 독립 Bool이라
    /// true로 남으면 버튼이 영영 비활성이었다.
    @Test
    func settingBusy_withoutCardOrRegistration_staysIdle() {
        #expect(!HomeSessionState.empty.settingBusy(true).isBusy)
        #expect(!HomeSessionState.past(makeCard("A")).settingBusy(true).isBusy)
    }

    @Test
    func arming_keepsExistingCard() {
        let session = HomeSessionState.card(makeCard("A"), busy: true)
            .arming(makeRegistration("A", syncedAt: .init()), busy: false)

        #expect(session.card?.routeId == "A")
        #expect(session.registration?.routeId == "A")
        #expect(!session.isBusy)
    }

    // MARK: - 칩

    /// 텍스트 없이 busy일 수 없다 — 숨겨진 칩이 진행 중인 조합을 표현할 수 없다.
    @Test
    func chip_busyWithoutText_collapsesToHidden() {
        #expect(HomeChipState.hidden.busy(true) == .hidden)
        #expect(HomeChipState.ready(text: "→ 강남역").withText(nil) == .hidden)
    }

    /// 재조회는 텍스트만 갈아 끼운다 — 진행 중 여부는 탭이 정한 것이라 보존한다.
    @Test
    func chip_withText_preservesBusy() {
        #expect(HomeChipState.busy(text: "→ 강남역").withText("→ 홍대입구역") == .busy(text: "→ 홍대입구역"))
        #expect(HomeChipState.ready(text: "→ 강남역").withText("→ 홍대입구역") == .ready(text: "→ 홍대입구역"))
    }
}
