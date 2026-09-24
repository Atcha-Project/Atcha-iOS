import Domain
import Foundation

// Convention: every ViewModel in the codebase is @MainActor.
@MainActor
final class SettingsViewModel {
    enum Route: Equatable {
        case homeAddress
        case withdraw
        case externalLink(URL)
    }

    enum Row: Equatable {
        case homeAddress(subtitle: String)
        case privacyPolicy
        case feedback
        case version(text: String, hasUpdate: Bool)
        case logout
        case withdraw
    }

    struct Section: Equatable {
        let title: String?
        let rows: [Row]
    }

    /// 화면 상태 전부를 담는다 — State 밖에 상태를 두지 않는 것이 이 코드베이스의
    /// ViewModel 규약이다. 이전에는 `sections`(렌더 결과)가 상태 자리에 있고 실제
    /// 상태 셋이 private 필드로 흩어져 있어서, "로딩 중 + 업데이트 있음 + 로그아웃 중"
    /// 같은 조합을 검증하려면 ViewModel을 통째로 조립해야 했다.
    struct State: Equatable {
        var addressText = "불러오는 중…"
        var hasUpdate = false
        var isLoggingOut = false
    }

    /// Set by the ViewController; always invoked on the main actor.
    var onSectionsChange: (([Section]) -> Void)?
    var onToast: ((String) -> Void)?
    /// Set by the Coordinator.
    var onRoute: ((Route) -> Void)?

    private(set) var state = State() {
        didSet { if state != oldValue { onSectionsChange?(sections) } }
    }

    /// 상태에서 파생되는 렌더 모델 — 저장하지 않는다.
    var sections: [Section] { Self.sections(from: state, currentVersion: currentVersion) }

    private let getUserProfileUseCase: any GetUserProfileUseCase
    private let logoutUseCase: any LogoutUseCase
    private let checkAppUpdateUseCase: (any CheckAppUpdateUseCase)?
    private let currentVersion: String
    private let appStoreURL: URL?

    private var profileTask: Task<Void, Never>?
    private var updateTask: Task<Void, Never>?
    private var logoutTask: Task<Void, Never>?

    init(
        getUserProfileUseCase: any GetUserProfileUseCase,
        logoutUseCase: any LogoutUseCase,
        checkAppUpdateUseCase: (any CheckAppUpdateUseCase)? = nil,
        currentVersion: String,
        appStoreURL: URL? = nil
    ) {
        self.getUserProfileUseCase = getUserProfileUseCase
        self.logoutUseCase = logoutUseCase
        self.checkAppUpdateUseCase = checkAppUpdateUseCase
        self.currentVersion = currentVersion
        self.appStoreURL = appStoreURL
    }

    deinit {
        profileTask?.cancel()
        updateTask?.cancel()
        logoutTask?.cancel()
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
        case .withdraw: onRoute?(.withdraw)
        // 확인 팝업은 VC 몫 — 확정되면 logoutConfirmed()로 들어온다.
        case .logout: break
        }
    }

    /// 로그인 화면 복귀는 세션 만료 관찰(App)이 한다 — 여기선 중복 탭만 막는다.
    func logoutConfirmed() {
        guard !state.isLoggingOut else { return }
        state.isLoggingOut = true
        logoutTask = Task { [weak self] in
            guard let useCase = self?.logoutUseCase else { return }
            await useCase.execute()
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
            self?.state.addressText = text
        }
    }

    private func checkForUpdate() {
        guard let checkAppUpdateUseCase else { return }
        let currentVersion = currentVersion
        updateTask = Task { [weak self] in
            // 실패는 무음 — 버전 행은 현재 버전만 보여 준다.
            guard case .recommended = try? await checkAppUpdateUseCase.execute(currentVersion: currentVersion),
                  !Task.isCancelled else { return }
            self?.state.hasUpdate = true
        }
    }

    /// 순수 함수 — 상태만 있으면 ViewModel 없이도 렌더 결과를 검증할 수 있다.
    nonisolated static func sections(from state: State, currentVersion: String) -> [Section] {
        [
            Section(title: "내 정보", rows: [.homeAddress(subtitle: state.addressText)]),
            Section(title: "앱 정보", rows: [
                .privacyPolicy,
                .feedback,
                .version(text: currentVersion, hasUpdate: state.hasUpdate),
            ]),
            Section(title: nil, rows: [.logout, .withdraw]),
        ]
    }
}
