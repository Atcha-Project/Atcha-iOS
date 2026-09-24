import Domain
import Foundation

// Convention: every ViewModel in the codebase is @MainActor.
@MainActor
final class SettingsViewModel {
    enum Route: Equatable {
        case homeAddress
        case externalLink(URL)
    }

    enum Row: Equatable {
        case homeAddress(subtitle: String)
        case privacyPolicy
        case feedback
        case version(text: String, hasUpdate: Bool)
    }

    struct Section: Equatable {
        let title: String?
        let rows: [Row]
    }

    /// Set by the ViewController; always invoked on the main actor.
    var onSectionsChange: (([Section]) -> Void)?
    var onToast: ((String) -> Void)?
    /// Set by the Coordinator.
    var onRoute: ((Route) -> Void)?

    private(set) var sections: [Section] = [] {
        didSet { if sections != oldValue { onSectionsChange?(sections) } }
    }

    private var addressText = "불러오는 중…"
    private var hasUpdate = false

    private let getUserProfileUseCase: any GetUserProfileUseCase
    private let checkAppUpdateUseCase: (any CheckAppUpdateUseCase)?
    private let currentVersion: String
    private let appStoreURL: URL?

    private var profileTask: Task<Void, Never>?
    private var updateTask: Task<Void, Never>?

    init(
        getUserProfileUseCase: any GetUserProfileUseCase,
        checkAppUpdateUseCase: (any CheckAppUpdateUseCase)? = nil,
        currentVersion: String,
        appStoreURL: URL? = nil
    ) {
        self.getUserProfileUseCase = getUserProfileUseCase
        self.checkAppUpdateUseCase = checkAppUpdateUseCase
        self.currentVersion = currentVersion
        self.appStoreURL = appStoreURL
        rebuildSections()
    }

    deinit {
        profileTask?.cancel()
        updateTask?.cancel()
    }

    func viewDidLoad() {
        loadProfile()
        checkForUpdate()
    }

    /// 주소 변경 화면이 저장에 성공하고 돌아왔을 때 — 서버 값으로 다시 읽는다(캐시 없음).
    func homeAddressDidChange() {
        onToast?("집 주소가 변경되었어요")
        loadProfile()
    }

    func didSelect(_ row: Row) {
        switch row {
        case .homeAddress: onRoute?(.homeAddress)
        case .privacyPolicy: onRoute?(.externalLink(SettingsLinks.privacyPolicy))
        case .feedback: onRoute?(.externalLink(SettingsLinks.feedbackForm))
        case .version(_, hasUpdate: true):
            if let appStoreURL { onRoute?(.externalLink(appStoreURL)) }
        case .version: break
        }
    }

    private func loadProfile() {
        profileTask?.cancel()
        profileTask = Task { [weak self] in
            guard let useCase = self?.getUserProfileUseCase else { return }
            let text: String
            do {
                let profile = try await useCase.execute()
                let address = profile.address?.trimmingCharacters(in: .whitespaces) ?? ""
                text = address.isEmpty ? "집 주소를 등록해 주세요" : address
            } catch {
                text = "주소를 불러오지 못했어요"
            }
            guard !Task.isCancelled else { return }
            self?.addressText = text
            self?.rebuildSections()
        }
    }

    private func checkForUpdate() {
        guard let checkAppUpdateUseCase else { return }
        let currentVersion = currentVersion
        updateTask = Task { [weak self] in
            // 실패는 무음 — 버전 행은 현재 버전만 보여 준다.
            guard case .recommended = try? await checkAppUpdateUseCase.execute(currentVersion: currentVersion),
                  !Task.isCancelled else { return }
            self?.hasUpdate = true
            self?.rebuildSections()
        }
    }

    private func rebuildSections() {
        sections = [
            Section(title: "내 정보", rows: [.homeAddress(subtitle: addressText)]),
            Section(title: "앱 정보", rows: [
                .privacyPolicy,
                .feedback,
                .version(text: currentVersion, hasUpdate: hasUpdate),
            ]),
        ]
    }
}
