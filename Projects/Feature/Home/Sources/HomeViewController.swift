import DesignSystem
import Domain
import SearchFeatureInterface
import SnapKit
import UIKit

final class HomeViewController: UIViewController {
    // VC strongly owns the VM; the VM's closures capture the VC weakly.
    private let viewModel: HomeViewModel

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DSTypography.title1.font
        label.textColor = DSColor.Accent.default
        label.text = "앗차"
        return label
    }()

    private let banner = DSBanner()
    private let departureField = DSTextField(placeholder: "출발지를 검색해 주세요", showsAccentDot: true)
    private let arrivalField = DSTextField(placeholder: "도착지를 검색해 주세요")
    private lazy var departureRow = makeFieldRow(
        icon: DSIcon.myLocation24, field: departureField, entry: .departure
    )
    private lazy var arrivalRow = makeFieldRow(
        icon: DSIcon.place24, field: arrivalField, entry: .arrival
    )
    // 최근 경로 원탭 칩(Phase 18) — 자기 크기 컴포넌트라 스택 전폭으로 늘리지 않고
    // 래퍼의 leading에 붙인다. 표시·활성은 render가 State로 반영한다.
    private let recentRouteChip = DSChip()
    private lazy var chipRow: UIView = {
        let row = UIView()
        row.addSubview(recentRouteChip)
        recentRouteChip.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        return row
    }()
    private let routeCard = DSRouteCard()
    private let registerButton = DSButton(title: "알람 등록하기")
    // DSButton은 title이 init 고정이라 토글은 버튼 2개의 표시 전환으로 구현한다.
    private let cancelButton = DSButton(title: "알람 해제하기", style: .secondary)

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = DSSpacing.md
        return stack
    }()

    // pull-to-refresh(Phase 16) — 콘텐츠가 화면보다 짧아도 당길 수 있게 상시 바운스.
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    private let refreshControl = UIRefreshControl()

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        viewModel.viewDidLoad()
        // 설정을 다녀온 뒤의 위치 권한 회복 재확인(Phase 15) — 재조회 여부는 VM이 판정한다.
        // 셀렉터 기반 관찰: 해제가 자동(iOS 9+)이라 deinit 정리가 필요 없고, 알림은
        // 메인 스레드에서 발송되므로 MainActor VC 메서드 직결로 충분하다.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func handleDidBecomeActive() {
        viewModel.didBecomeActive()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 홈은 자체 타이틀을 그린다 — 시스템 내비바 숨김(Search와 동일 규약).
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // 검색 화면을 다녀오며 바뀐 최근 검색(삭제 포함)을 칩에 반영한다(Phase 18).
        viewModel.viewWillAppear()
    }

    // MARK: - UI

    private func configureUI() {
        view.backgroundColor = DSColor.Background.base

        refreshControl.addAction(
            UIAction { [weak self] _ in self?.viewModel.refreshPulled() },
            for: .valueChanged
        )
        scrollView.refreshControl = refreshControl
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(DSSpacing.sm12)
            make.bottom.equalTo(scrollView.contentLayoutGuide)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(DSSpacing.md)
            // 세로 스크롤 전용 — 콘텐츠 폭을 프레임 폭에 고정한다(수평 스크롤 방지).
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-DSSpacing.md * 2)
        }

        [titleLabel, banner, departureRow, arrivalRow, chipRow, routeCard, registerButton, cancelButton]
            .forEach(contentStack.addArrangedSubview)
        contentStack.addArrangedSubview(makeCaptionStack())
        contentStack.setCustomSpacing(DSSpacing.lg20, after: titleLabel)
        contentStack.setCustomSpacing(DSSpacing.sm, after: departureRow)
        // 칩이 숨겨져도 필드→카드 간격이 기존(lg)과 같도록 앞뒤 모두 lg를 쓴다.
        contentStack.setCustomSpacing(DSSpacing.lg, after: arrivalRow)
        contentStack.setCustomSpacing(DSSpacing.lg, after: chipRow)

        banner.isHidden = true
        chipRow.isHidden = true
        routeCard.isHidden = true
        registerButton.isHidden = true
        cancelButton.isHidden = true

        recentRouteChip.addAction(
            UIAction { [weak self] _ in self?.viewModel.chipTapped() },
            for: .touchUpInside
        )
        registerButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.registerAlarmTapped() },
            for: .touchUpInside
        )
        cancelButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.cancelAlarmTapped() },
            for: .touchUpInside
        )
    }

    /// 홈의 필드는 편집이 아니라 검색 진입 트리거다. DSTextField에는 편집 시작 훅이
    /// 없으므로 필드 터치를 통째로 죽이고 UIControl 래퍼가 탭을 가져간다.
    /// 탭한 필드가 검색 진입 슬롯이 된다(Phase 17) — entry가 그대로 넘어간다.
    private func makeFieldRow(
        icon: UIImage, field: DSTextField, entry: SearchEntryField
    ) -> UIControl {
        let row = UIControl()
        let iconView = UIImageView(image: icon)
        iconView.tintColor = DSColor.Icon.default
        iconView.contentMode = .scaleAspectFit
        field.isUserInteractionEnabled = false

        [iconView, field].forEach(row.addSubview)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(DSIconSize.lg)
        }
        field.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(DSSpacing.sm)
            make.top.trailing.bottom.equalToSuperview()
        }
        row.addAction(
            UIAction { [weak self] _ in self?.viewModel.searchFieldTapped(entry) },
            for: .touchUpInside
        )
        return row
    }

    private func makeCaptionStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = DSSpacing.xs
        [
            "막차 시간과 가까워질수록 정확해져요",
            "알람 시간은 막차 환경에 따라 변경될 수 있어요",
        ].forEach { stack.addArrangedSubview(makeCaptionRow(text: $0)) }
        return stack
    }

    private func makeCaptionRow(text: String) -> UIView {
        let row = UIView()
        let iconView = UIImageView(image: DSIcon.info16)
        iconView.tintColor = DSColor.Icon.muted
        iconView.contentMode = .scaleAspectFit
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = DSTypography.caption1.attributed(text, color: DSColor.Text.secondary)

        [iconView, label].forEach(row.addSubview)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalTo(label.snp.centerY)
            make.size.equalTo(DSIconSize.sm)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(DSSpacing.xs)
            make.top.trailing.bottom.equalToSuperview()
        }
        return row
    }

    // MARK: - 바인딩

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        viewModel.onToast = { [weak self] event in
            self?.showToast(for: event)
        }
        // 성공/실패 불문 동기화 종료 시 스피너를 내린다(Phase 16) — 실패 표출은
        // 스탬프가 낡은 시각을 유지하는 것뿐(무음 정책).
        viewModel.onManualSyncFinished = { [weak self] in
            self?.refreshControl.endRefreshing()
        }
        render(viewModel.state)
    }

    private func render(_ state: HomeViewModel.State) {
        switch state.departure {
        case .loading:
            departureField.setText("현재 위치 확인 중...")
        case let .current(name):
            departureField.setText(name)
        case .needsSearch:
            // 빈 값이면 placeholder("출발지를 검색해 주세요")가 유도 문구 역할을 한다.
            departureField.setText("")
        }

        // 도착지 필드 = 선택 경로의 도착지명(Phase 17). nil이면 placeholder가 유도한다.
        arrivalField.setText(state.arrivalText ?? "")

        // 최근 경로 원탭 칩(Phase 18) — nil이면 숨김, 재검색 진행 중엔 비활성(더블 탭 방지).
        if let chipText = state.recentRouteChipText {
            recentRouteChip.setText(chipText)
            chipRow.isHidden = false
        } else {
            chipRow.isHidden = true
        }
        recentRouteChip.isEnabled = !state.isChipBusy

        if let card = state.routeCard {
            // 신선도 스탬프(Phase 16)는 세션 상태라 State가 따로 나른다 — 표출 시점 합성.
            routeCard.configure(with: card.dsContent(footnote: state.freshnessText))
            routeCard.isHidden = false
        } else {
            routeCard.isHidden = true
        }
        registerButton.isHidden = state.alarmButton != .register
        cancelButton.isHidden = state.alarmButton != .cancel
        registerButton.isEnabled = !state.isAlarmBusy
        cancelButton.isEnabled = !state.isAlarmBusy

        if let bannerData = state.banner {
            banner.configure(
                text: bannerData.text,
                style: Self.bannerStyle(for: bannerData.urgency),
                detailText: state.freshnessText
            )
            banner.isHidden = false
        } else {
            banner.isHidden = true
        }
    }

    /// 긴급도 3단계 ↔ DSBanner.Style 매핑 — LA와 같은 척도(여유/주의/임박)를 그대로 쓴다.
    private static func bannerStyle(for urgency: LastTrainUrgency) -> DSBanner.Style {
        switch urgency {
        case .relaxed: .normal
        case .caution: .caution
        case .imminent: .urgent
        }
    }

    private func showToast(for event: HomeViewModel.ToastEvent) {
        switch event {
        case .locationPermissionNeeded:
            DSToast.show(
                "위치 권한이 꺼져 있어요",
                in: view,
                action: .init(title: "설정으로 이동") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            )
        case .locationServicesDisabled:
            DSToast.show(
                "기기의 위치 서비스가 꺼져 있어요",
                in: view,
                action: .init(title: "설정으로 이동") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            )
        case .locationRestricted:
            // restricted는 설정으로 못 푸는 제약 — "설정으로 이동"을 안내하지 않는다(Phase 17).
            DSToast.show("이 기기에선 위치를 사용할 수 없어요. 출발지를 검색해 주세요", in: view)
        case .chipLocationUnavailable:
            DSToast.show("현재 위치를 확인하지 못했어요. 잠시 후 다시 시도해 주세요", in: view)
        case .chipSearchFailed:
            DSToast.show("막차를 찾지 못했어요. 다시 시도해 주세요", in: view)
        case .chipServiceEnded:
            // 검색 화면 빈 상태 제목과 같은 어휘(Phase 18) — 화면 간 표기 통일.
            DSToast.show("오늘 막차가 끊겼어요", in: view)
        case .chipNoRoute:
            DSToast.show("대중교통 경로를 찾지 못했어요", in: view)
        case .alarmPermissionNeeded:
            DSToast.show(
                "알람 권한이 꺼져 있어요",
                in: view,
                action: .init(title: "설정으로 이동") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            )
        case .alarmRegisterFailed:
            DSToast.show("알람 등록에 실패했어요. 다시 시도해 주세요.", in: view)
        case .alarmTooLate:
            DSToast.show("이미 출발 시간이 지난 경로예요", in: view)
        case .notificationPermissionDenied:
            DSToast.show(
                "막차 변경 알림을 받으려면 설정에서 알림을 허용해주세요",
                in: view,
                action: .init(title: "설정으로 이동") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            )
        case .alarmCancelFailed:
            DSToast.show("알람 해제에 실패했어요. 다시 시도해 주세요.", in: view)
        case let .lastTrainAdvanced(minutes):
            // 배너 강조는 이 원샷 이벤트에 부수하는 시각 효과 — 별도 채널을 만들지 않는다.
            // 배너의 시각·긴급도 값 자체는 info 스트림이 State로 이미 갱신한다.
            DSToast.show("막차가 \(minutes)분 당겨졌어요", in: view)
            banner.emphasize()
        case .lastTrainMissed:
            // TODO: [미확정 #9] 대안 제시(심야버스 등) 데이터 소스 확정 전까지 실패 문구만 표출한다.
            DSToast.show("막차가 지나갔어요", in: view)
        case .lastTrainServiceEnded:
            DSToast.show("오늘 운행이 끝나 알람을 정리했어요", in: view)
        }
    }
}
