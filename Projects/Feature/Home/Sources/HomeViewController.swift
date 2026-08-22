import DesignSystem
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
    private lazy var departureRow = makeFieldRow(icon: DSIcon.myLocation24, field: departureField)
    private lazy var arrivalRow = makeFieldRow(icon: DSIcon.place24, field: arrivalField)
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
        // "SceneDelegate → 알림 경유": scene 포그라운드 전환마다 시스템이 게시하는
        // 노티를 관찰한다 (최초 진입 포함 — 알람 상태 복원을 겸한다).
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneWillEnterForeground),
            name: UIScene.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func sceneWillEnterForeground() {
        viewModel.appWillEnterForeground()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 홈은 자체 타이틀을 그린다 — 시스템 내비바 숨김(Search와 동일 규약).
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - UI

    private func configureUI() {
        view.backgroundColor = DSColor.Background.base

        view.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(DSSpacing.sm12)
            make.leading.trailing.equalToSuperview().inset(DSSpacing.md)
        }

        [titleLabel, banner, departureRow, arrivalRow, routeCard, registerButton, cancelButton]
            .forEach(contentStack.addArrangedSubview)
        contentStack.addArrangedSubview(makeCaptionStack())
        contentStack.setCustomSpacing(DSSpacing.lg20, after: titleLabel)
        contentStack.setCustomSpacing(DSSpacing.sm, after: departureRow)
        contentStack.setCustomSpacing(DSSpacing.lg, after: arrivalRow)

        banner.isHidden = true
        routeCard.isHidden = true
        registerButton.isHidden = true
        cancelButton.isHidden = true

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
    private func makeFieldRow(icon: UIImage, field: DSTextField) -> UIControl {
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
            UIAction { [weak self] _ in self?.viewModel.searchFieldTapped() },
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

        if let card = state.routeCard {
            routeCard.configure(with: card.dsContent)
            routeCard.isHidden = false
        } else {
            routeCard.isHidden = true
        }
        registerButton.isHidden = state.alarmButton != .register
        cancelButton.isHidden = state.alarmButton != .cancel
        registerButton.isEnabled = !state.isAlarmBusy
        cancelButton.isEnabled = !state.isAlarmBusy

        if let bannerData = state.banner {
            banner.configure(text: bannerData.text, style: bannerData.isUrgent ? .urgent : .normal)
            banner.isHidden = false
        } else {
            banner.isHidden = true
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
        case .alarmCancelFailed:
            DSToast.show("알람 해제에 실패했어요. 다시 시도해 주세요.", in: view)
        }
    }
}
