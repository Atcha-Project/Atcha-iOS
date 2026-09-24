@testable import SettingsFeature
import Domain
import Testing

@MainActor
struct HomeAddressViewModelTests {
    private let place = Place(
        name: "서울시청", address: "서울 중구 세종대로 110",
        coordinate: Coordinate(latitude: 37.5665, longitude: 126.9780)
    )

    private func makeSUT(
        update: SpyUpdateHomeAddressUseCase,
        locationFails: Bool = false
    ) -> HomeAddressViewModel {
        HomeAddressViewModel(
            searchPlacesUseCase: StubSearchPlacesUseCase(places: [place]),
            getCurrentLocationUseCase: StubGetCurrentLocationUseCase(fails: locationFails),
            reverseGeocodeUseCase: StubReverseGeocodeUseCase(),
            updateHomeAddressUseCase: update,
            debounceInterval: .zero
        )
    }

    @Test
    func search_thenSelect_savesAddress() async {
        let update = SpyUpdateHomeAddressUseCase()
        let sut = makeSUT(update: update)
        var savedCount = 0
        sut.onSaved = { savedCount += 1 }

        sut.keywordDidChange("시청")
        await waitUntil { if case .places = sut.state { true } else { false } }
        sut.didSelectPlace(at: 0)
        await waitUntil { savedCount == 1 }

        #expect(update.addresses == ["서울 중구 세종대로 110"])
        #expect(savedCount == 1)
    }

    @Test
    func outOfServiceRegion_showsLegacyToast() async {
        let update = SpyUpdateHomeAddressUseCase()
        update.error = UpdateHomeAddressError.outOfServiceRegion
        let sut = makeSUT(update: update)
        var toasts: [String] = []
        sut.onToast = { toasts.append($0) }

        sut.useCurrentLocationTapped()
        await waitUntil { !toasts.isEmpty }

        #expect(toasts == ["앗차는 현재 서울, 경기, 인천에서만 이용 가능해요"])
        #expect(sut.isSaving == false)
    }

    @Test
    func currentLocationFailure_toastsWithoutSaving() async {
        let update = SpyUpdateHomeAddressUseCase()
        let sut = makeSUT(update: update, locationFails: true)
        var toasts: [String] = []
        sut.onToast = { toasts.append($0) }

        sut.useCurrentLocationTapped()
        await waitUntil { !toasts.isEmpty }

        #expect(update.addresses.isEmpty)
        #expect(toasts == ["현재 위치를 확인하지 못했어요. 잠시 후 다시 시도해 주세요"])
    }
}
