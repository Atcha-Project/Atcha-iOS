@testable import SettingsFeature
import Domain
import Foundation
import Testing

@MainActor
struct SettingsViewModelTests {
    private func makeSUT(
        address: String? = "서울 중구 세종대로 110",
        profileFails: Bool = false,
        update: AppUpdateStatus = .upToDate
    ) -> SettingsViewModel {
        SettingsViewModel(
            getUserProfileUseCase: StubGetUserProfileUseCase(address: address, fails: profileFails),
            checkAppUpdateUseCase: StubCheckAppUpdateUseCase(status: update),
            currentVersion: "2.0.0",
            appStoreURL: URL(string: "itms-apps://example")
        )
    }

    private func homeSubtitle(_ sut: SettingsViewModel) -> String? {
        guard case let .homeAddress(subtitle) = sut.sections.first?.rows.first else { return nil }
        return subtitle
    }

    @Test
    func viewDidLoad_showsServerAddress() async {
        let sut = makeSUT()
        sut.viewDidLoad()
        await waitUntil { homeSubtitle(sut) == "서울 중구 세종대로 110" }
        #expect(homeSubtitle(sut) == "서울 중구 세종대로 110")
    }

    @Test
    func viewDidLoad_profileFailure_showsFailureCopy() async {
        let sut = makeSUT(profileFails: true)
        sut.viewDidLoad()
        await waitUntil { homeSubtitle(sut) == "주소를 불러오지 못했어요" }
        #expect(homeSubtitle(sut) == "주소를 불러오지 못했어요")
    }

    @Test
    func updateAvailable_versionRowRoutesToStore() async {
        let sut = makeSUT(update: .recommended(latest: "2.1.0"))
        var routes: [SettingsViewModel.Route] = []
        sut.onRoute = { routes.append($0) }
        sut.viewDidLoad()
        let updatedRow = SettingsViewModel.Row.version(text: "2.0.0", hasUpdate: true)
        await waitUntil { sut.sections.contains { $0.rows.contains(updatedRow) } }

        sut.didSelect(updatedRow)

        #expect(routes == [.externalLink(URL(string: "itms-apps://example")!)])
    }

    @Test
    func homeAddressDidChange_toastsAndReloads() {
        let sut = makeSUT()
        var toasts: [String] = []
        sut.onToast = { toasts.append($0) }

        sut.homeAddressDidChange()

        #expect(toasts == ["집 주소가 변경되었어요"])
    }
}
