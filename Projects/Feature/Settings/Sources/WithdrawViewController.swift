import DesignSystem
import SnapKit
import UIKit

final class WithdrawViewController: SettingsScreen {
    // VC strongly owns the VM; the VM's closures capture the VC weakly.
    private let viewModel: WithdrawViewModel
    private let scrollView = UIScrollView()
    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = DSSpacing.sm
        return stack
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = DSTypography.title2.attributed(
            "떠나시는 이유를 알려주세요", color: DSColor.Text.primary
        )
        return label
    }()
    private var reasonButtons: [WithdrawViewModel.Reason: UIButton] = [:]
    private let otherField = DSTextField(placeholder: "이유를 입력해 주세요")
    private let submitButton = DSButton(title: "탈퇴하기")

    init(viewModel: WithdrawViewModel) {
        self.viewModel = viewModel
        super.init(title: "계정 탈퇴")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }

    private func configureUI() {
        scrollView.keyboardDismissMode = .onDrag
        [scrollView, submitButton].forEach(contentView.addSubview)
        scrollView.addSubview(stack)
        submitButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(DSSpacing.md)
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-DSSpacing.sm)
        }
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(submitButton.snp.top).offset(-DSSpacing.sm)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(DSSpacing.md)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-DSSpacing.md * 2)
        }

        stack.addArrangedSubview(titleLabel)
        stack.setCustomSpacing(DSSpacing.lg, after: titleLabel)
        for reason in WithdrawViewModel.Reason.allCases {
            let button = makeReasonButton(reason)
            reasonButtons[reason] = button
            stack.addArrangedSubview(button)
        }
        stack.addArrangedSubview(otherField)
        otherField.isHidden = true
        otherField.onTextChange = { [weak self] text in
            self?.viewModel.otherTextDidChange(text)
        }

        submitButton.addAction(
            UIAction { [weak self] _ in
                self?.confirm(title: "탈퇴하시겠어요?", confirmTitle: "탈퇴하기") {
                    self?.viewModel.withdrawConfirmed()
                }
            },
            for: .touchUpInside
        )
    }

    private func makeReasonButton(_ reason: WithdrawViewModel.Reason) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = reason.title
        configuration.imagePadding = DSSpacing.sm12
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: DSSpacing.sm12, leading: 0, bottom: DSSpacing.sm12, trailing: 0
        )
        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        button.tintColor = DSColor.Text.primary
        button.accessibilityTraits.insert(.button)
        button.addAction(
            UIAction { [weak self] _ in self?.viewModel.select(reason) },
            for: .touchUpInside
        )
        return button
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        viewModel.onToast = { [weak self] message in
            self?.showToast(message)
        }
        render(viewModel.state)
    }

    private func render(_ state: WithdrawViewModel.State) {
        for (reason, button) in reasonButtons {
            let isSelected = reason == state.selected
            let tint = isSelected ? DSColor.Accent.default : DSColor.Icon.muted
            button.configuration?.image = UIImage(systemName: isSelected ? "largecircle.fill.circle" : "circle")?
                .withTintColor(tint, renderingMode: .alwaysOriginal)
            button.configuration?.baseForegroundColor = DSColor.Text.primary
            button.accessibilityTraits = isSelected ? [.button, .selected] : .button
        }
        if otherField.isHidden == state.isOtherInputVisible {
            otherField.isHidden = !state.isOtherInputVisible
        }
        submitButton.isEnabled = state.canSubmit
    }
}
