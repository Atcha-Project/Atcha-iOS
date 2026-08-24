import DesignSystem
import UIKit

/// Dumb splash screen: legacy splash visuals (full-bleed background + character/logo stack)
/// while the auth bootstrap runs, a retry affordance when it fails.
/// All flow decisions live in AppCoordinator.
final class SplashViewController: UIViewController {
    var onRetryTapped: (() -> Void)?

    private let backgroundImageView = UIImageView()
    private let characterImageView = UIImageView()
    private let logoImageView = UIImageView()
    private let logoStackView = UIStackView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let retryStack = UIStackView()
    private let messageLabel = UILabel()
    private let retryButton = DSButton(title: "다시 시도")

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    func showLoading() {
        retryStack.isHidden = true
        activityIndicator.startAnimating()
    }

    /// 실패 원인별 문구(Phase 16) — 선택은 호출자(AppCoordinator + BootstrapFailureMessage)가 한다.
    func showRetry(message: String) {
        messageLabel.text = message
        activityIndicator.stopAnimating()
        retryStack.isHidden = false
    }

    private func configureUI() {
        view.backgroundColor = DSColor.Background.base

        backgroundImageView.image = AtchaV2Asset.splashBackground.image
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true

        characterImageView.image = AtchaV2Asset.splashCharacter.image
        characterImageView.contentMode = .scaleAspectFit
        logoImageView.image = AtchaV2Asset.splashLogo.image
        logoImageView.contentMode = .scaleAspectFit

        logoStackView.axis = .vertical
        logoStackView.alignment = .center
        logoStackView.spacing = 12
        logoStackView.addArrangedSubview(characterImageView)
        logoStackView.addArrangedSubview(logoImageView)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = DSColor.Text.primary

        messageLabel.font = DSTypography.body1.font
        messageLabel.textColor = DSColor.Text.primary
        messageLabel.textAlignment = .center

        retryButton.addAction(
            UIAction { [weak self] _ in self?.onRetryTapped?() },
            for: .touchUpInside
        )

        retryStack.axis = .vertical
        retryStack.alignment = .center
        retryStack.spacing = DSSpacing.md
        retryStack.isHidden = true
        retryStack.addArrangedSubview(messageLabel)
        retryStack.addArrangedSubview(retryButton)

        for subview in [backgroundImageView, logoStackView, activityIndicator, retryStack] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // 런치스크린 storyboard와 동일한 정중앙 배치 — 전환 시 로고가 튀지 않게 유지.
            logoStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: logoStackView.bottomAnchor, constant: DSSpacing.xl),
            retryStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryStack.topAnchor.constraint(equalTo: logoStackView.bottomAnchor, constant: DSSpacing.xl),
            retryStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: DSSpacing.md),
            retryStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -DSSpacing.md),
        ])
    }
}
