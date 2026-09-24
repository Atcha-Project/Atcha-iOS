import Domain
import Foundation

// Convention: every ViewModel in the codebase is @MainActor.
@MainActor
final class HomeAddressViewModel {
    struct PlaceViewData: Equatable {
        let name: String
        let address: String
    }

    enum State: Equatable {
        case idle
        case loading
        case places([PlaceViewData])
        case empty
        case failed(message: String)
    }

    /// Set by the ViewController; always invoked on the main actor.
    var onStateChange: ((State) -> Void)?
    var onSavingChange: ((Bool) -> Void)?
    var onToast: ((String) -> Void)?
    /// Set by the Coordinator — 저장 성공 시 1회.
    var onSaved: (() -> Void)?

    private(set) var state: State = .idle {
        didSet { if state != oldValue { onStateChange?(state) } }
    }

    private(set) var isSaving = false {
        didSet { if isSaving != oldValue { onSavingChange?(isSaving) } }
    }

    private var listedPlaces: [Place] = []
    private let searchPlacesUseCase: any SearchPlacesUseCase
    private let getCurrentLocationUseCase: any GetCurrentLocationUseCase
    private let reverseGeocodeUseCase: any ReverseGeocodeUseCase
    private let updateHomeAddressUseCase: any UpdateHomeAddressUseCase
    private let debounceInterval: Duration

    private var searchTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?

    init(
        searchPlacesUseCase: any SearchPlacesUseCase,
        getCurrentLocationUseCase: any GetCurrentLocationUseCase,
        reverseGeocodeUseCase: any ReverseGeocodeUseCase,
        updateHomeAddressUseCase: any UpdateHomeAddressUseCase,
        debounceInterval: Duration = .milliseconds(300)
    ) {
        self.searchPlacesUseCase = searchPlacesUseCase
        self.getCurrentLocationUseCase = getCurrentLocationUseCase
        self.reverseGeocodeUseCase = reverseGeocodeUseCase
        self.updateHomeAddressUseCase = updateHomeAddressUseCase
        self.debounceInterval = debounceInterval
    }

    deinit {
        searchTask?.cancel()
        saveTask?.cancel()
    }

    func keywordDidChange(_ keyword: String) {
        searchTask?.cancel()
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            listedPlaces = []
            state = .idle
            return
        }
        // [weak self]: the in-flight task must not keep the ViewModel alive.
        searchTask = Task { [weak self] in
            guard let interval = self?.debounceInterval,
                  let useCase = self?.searchPlacesUseCase else { return }
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            self?.state = .loading
            do {
                let places = try await useCase.execute(keyword: trimmed, near: nil)
                guard !Task.isCancelled else { return }
                self?.listedPlaces = places
                self?.state = places.isEmpty
                    ? .empty
                    : .places(places.map { PlaceViewData(name: $0.name, address: $0.address) })
            } catch {
                guard !Task.isCancelled else { return }
                self?.state = .failed(message: "검색에 실패했어요")
            }
        }
    }

    func didSelectPlace(at index: Int) {
        guard listedPlaces.indices.contains(index) else { return }
        save(listedPlaces[index])
    }

    /// 현재 위치 → 역지오코딩 주소로 저장(레거시 "현위치 찾기").
    func useCurrentLocationTapped() {
        guard !isSaving else { return }
        isSaving = true
        saveTask = Task { [weak self] in
            guard let locate = self?.getCurrentLocationUseCase,
                  let geocode = self?.reverseGeocodeUseCase else { return }
            do {
                let coordinate = try await locate.execute()
                let place = try await geocode.execute(coordinate: coordinate)
                guard !Task.isCancelled else { return }
                self?.isSaving = false
                self?.save(place)
            } catch {
                guard !Task.isCancelled else { return }
                self?.isSaving = false
                self?.onToast?("현재 위치를 확인하지 못했어요. 잠시 후 다시 시도해 주세요")
            }
        }
    }

    private func save(_ place: Place) {
        guard !isSaving else { return }
        isSaving = true
        // 검색 결과는 도로명 주소가 비어 있을 수 있다 — 이름으로 대신한다.
        let address = place.address.isEmpty ? place.name : place.address
        saveTask = Task { [weak self] in
            guard let useCase = self?.updateHomeAddressUseCase else { return }
            do {
                try await useCase.execute(address: address, coordinate: place.coordinate)
                guard !Task.isCancelled else { return }
                self?.isSaving = false
                self?.onSaved?()
            } catch UpdateHomeAddressError.outOfServiceRegion {
                guard !Task.isCancelled else { return }
                self?.isSaving = false
                self?.onToast?("앗차는 현재 서울, 경기, 인천에서만 이용 가능해요")
            } catch {
                guard !Task.isCancelled else { return }
                self?.isSaving = false
                self?.onToast?("집 주소를 변경하지 못했어요. 다시 시도해 주세요")
            }
        }
    }
}
