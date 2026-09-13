import DesignSystem
import Domain
import SearchFeatureInterface
import SnapKit
import UIKit

final class HomeViewController: UIViewController {
    // VC strongly owns the VM; the VM's closures capture the VC weakly.
    private let viewModel: HomeViewModel

    // 토스식 위계: 브랜드는 작은 워드마크로 물러나고 시각적 무게는 컨텍스트
    // 타이틀("어디로 가세요?")이 가져간다. 타이틀은 정적 카피 — 상태 무관.
    private let brandLabel: UILabel = {
        let label = UILabel()
        label.font = DSTypography.heading.font
        label.textColor = DSColor.Accent.default
        label.text = "앗차"
        return label
    }()

    private let bigTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = DSTypography.title1.attributed(
            "어디로 가세요?", color: DSColor.Text.primary
        )
        return label
    }()

    private let banner = DSBanner()
    private let departureRow = HomeFieldRow(
        icon: DSIcon.myLocation24, placeholder: "출발지를 검색해 주세요", showsAccentDot: true
    )
    private let arrivalRow = HomeFieldRow(
        icon: DSIcon.place24, placeholder: "도착지를 검색해 주세요"
    )
    private lazy var fieldCard = DSGroupedCard(rows: [departureRow, arrivalRow])
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
    // 칩 위에 섹션 헤더를 얹는다 — 표시·숨김은 헤더와 칩이 한 몸으로 움직인다.
    private lazy var recentSection: UIStackView = {
        let header = UILabel()
        header.font = DSTypography.label2.font
        header.textColor = DSColor.Text.secondary
        header.text = "최근 경로"
        let stack = UIStackView(arrangedSubviews: [header, chipRow])
        stack.axis = .vertical
        stack.spacing = DSSpacing.sm
        return stack
    }()
    private let routeCard = DSRouteCard()
    private let registerButton = DSButton(title: "알람 등록하기")
    // DSButton은 title이 init 고정이라 토글은 버튼 2개의 표시 전환으로 구현한다.
    private let cancelButton = DSButton(title: "알람 해제하기", style: .secondary)
    // 하단 고정 CTA — 스택이라 두 버튼 모두 숨김이면 높이 0으로 접힌다.
    private let ctaStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()
    // 토스트가 하단 CTA를 덮지 않도록 CTA 위에 얹는 통과형 호스트.
    private let toastHost = PassthroughView()

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

    // 진입 페이드는 최초 1회만 — 검색 왕복마다 재생하면 홈이 깜빡인다.
    private var hasPlayedEntry = false

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
        prepareEntryTransitionIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playEntryTransitionIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 하단 고정 CTA에 콘텐츠 끝이 가리지 않게 바닥 인셋을 맞춘다(숨김이면 0).
        // 동일 값 재대입 가드 — viewDidLayoutSubviews 재귀 레이아웃 루프 방지.
        let ctaHeight = ctaStack.bounds.height
        let bottomInset = ctaHeight > 0 ? ctaHeight + DSSpacing.md : 0
        if scrollView.contentInset.bottom != bottomInset {
            scrollView.contentInset.bottom = bottomInset
            scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }

    // MARK: - 진입 페이드 (최초 1회)

    private func prepareEntryTransitionIfNeeded() {
        guard !hasPlayedEntry else { return }
        let translation = UIAccessibility.isReduceMotionEnabled
            ? CGAffineTransform.identity
            : CGAffineTransform(translationX: 0, y: 8)
        [contentStack, ctaStack].forEach {
            $0.alpha = 0
            $0.transform = translation
        }
    }

    private func playEntryTransitionIfNeeded() {
        guard !hasPlayedEntry else { return }
        hasPlayedEntry = true
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) { [weak self] in
            guard let self else { return }
            [contentStack, ctaStack].forEach {
                $0.alpha = 1
                $0.transform = .identity
            }
        }
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

        [brandLabel, banner, bigTitleLabel, fieldCard, recentSection, routeCard]
            .forEach(contentStack.addArrangedSubview)
        contentStack.addArrangedSubview(makeCaptionStack())
        contentStack.setCustomSpacing(DSSpacing.lg20, after: bigTitleLabel)
        // 칩 섹션이 숨겨져도 카드→경로 카드 간격이 같도록 앞뒤 모두 lg를 쓴다.
        contentStack.setCustomSpacing(DSSpacing.lg, after: fieldCard)
        contentStack.setCustomSpacing(DSSpacing.lg, after: recentSection)
        contentStack.setCustomSpacing(DSSpacing.lg, after: routeCard)

        // 알람 CTA는 스크롤 밖 하단 고정(토스식) — 표시 토글은 render가 그대로 수행한다.
        [registerButton, cancelButton].forEach(ctaStack.addArrangedSubview)
        view.addSubview(ctaStack)
        ctaStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(DSSpacing.md)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(DSSpacing.sm)
        }

        view.addSubview(toastHost)
        toastHost.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(ctaStack.snp.top)
        }

        banner.isHidden = true
        recentSection.isHidden = true
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
        // 행 전체 탭 → 검색 진입. 탭한 필드가 검색 진입 슬롯이 된다(Phase 17).
        departureRow.addAction(
            UIAction { [weak self] _ in self?.viewModel.searchFieldTapped(.departure) },
            for: .touchUpInside
        )
        arrivalRow.addAction(
            UIAction { [weak self] _ in self?.viewModel.searchFieldTapped(.arrival) },
            for: .touchUpInside
        )

        [registerButton, cancelButton, recentRouteChip, departureRow, arrivalRow]
            .forEach { DSPressEffect.apply(to: $0) }
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
            departureRow.setText("현재 위치 확인 중...")
        case let .current(name):
            departureRow.setText(name)
        case .needsSearch:
            // 빈 값이면 placeholder("출발지를 검색해 주세요")가 유도 문구 역할을 한다.
            departureRow.setText("")
        }

        // 도착지 필드 = 선택 경로의 도착지명(Phase 17). nil이면 placeholder가 유도한다.
        arrivalRow.setText(state.arrivalText ?? "")

        // 최근 경로 원탭 칩(Phase 18) — nil이면 숨김, 재검색 진행 중엔 비활성(더블 탭 방지).
        if let chipText = state.recentRouteChipText {
            recentRouteChip.setText(chipText)
            recentSection.isHidden = false
        } else {
            recentSection.isHidden = true
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
                in: toastHost,
                action: .init(title: "설정으로 이동") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            )
        case .locationServicesDisabled:
            DSToast.show(
                "기기의 위치 서비스가 꺼져 있어요",
                in: toastHost,
                action: .init(title: "설정으로 이동") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            )
        case .locationRestricted:
            // restricted는 설정으로 못 푸는 제약 — "설정으로 이동"을 안내하지 않는다(Phase 17).
            DSToast.show("이 기기에선 위치를 사용할 수 없어요. 출발지를 검색해 주세요", in: toastHost)
        case .chipLocationUnavailable:
            DSToast.show("현재 위치를 확인하지 못했어요. 잠시 후 다시 시도해 주세요", in: toastHost)
        case .chipSearchFailed:
            DSToast.show("막차를 찾지 못했어요. 다시 시도해 주세요", in: toastHost)
        case .chipServiceEnded:
            // 검색 화면 빈 상태 제목과 같은 어휘(Phase 18) — 화면 간 표기 통일.
            DSToast.show("오늘 막차가 끊겼어요", in: toastHost)
        case .chipNoRoute:
            DSToast.show("대중교통 경로를 찾지 못했어요", in: toastHost)
        case .alarmPermissionNeeded:
            DSToast.show(
                "알람 권한이 꺼져 있어요",
                in: toastHost,
                action: .init(title: "설정으로 이동") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            )
        case .alarmRegisterFailed:
            DSToast.show("알람 등록에 실패했어요. 다시 시도해 주세요.", in: toastHost)
        case .alarmTooLate:
            DSToast.show("이미 출발 시간이 지난 경로예요", in: toastHost)
        case .notificationPermissionDenied:
            DSToast.show(
                "막차 변경 알림을 받으려면 설정에서 알림을 허용해주세요",
                in: toastHost,
                action: .init(title: "설정으로 이동") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            )
        case .alarmCancelFailed:
            DSToast.show("알람 해제에 실패했어요. 다시 시도해 주세요.", in: toastHost)
        case let .lastTrainAdvanced(minutes):
            // 배너 강조는 이 원샷 이벤트에 부수하는 시각 효과 — 별도 채널을 만들지 않는다.
            // 배너의 시각·긴급도 값 자체는 info 스트림이 State로 이미 갱신한다.
            DSToast.show("막차가 \(minutes)분 당겨졌어요", in: toastHost)
            banner.emphasize()
        case .lastTrainMissed:
            // TODO: [미확정 #9] 대안 제시(심야버스 등) 데이터 소스 확정 전까지 실패 문구만 표출한다.
            DSToast.show("막차가 지나갔어요", in: toastHost)
        case .lastTrainServiceEnded:
            DSToast.show("오늘 운행이 끝나 알람을 정리했어요", in: toastHost)
        }
    }
}
