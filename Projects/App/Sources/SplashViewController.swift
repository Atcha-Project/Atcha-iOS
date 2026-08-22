import DesignSystem
import UIKit

/// Dumb splash screen: logo while the auth bootstrap runs, a retry affordance
/// when it fails. All flow decisions live in AppCoordinator.
final class SplashViewController: UIViewController {
    var onRetryTapped: (() -> Void)?

    private let logoLabel = UILabel()
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

    func showRetry() {
        activityIndicator.stopAnimating()
        retryStack.isHidden = false
    }

    private func configureUI() {
        view.backgroundColor = DSColor.background

        logoLabel.text = "앗차"
        logoLabel.font = DSFont.title(34)
        logoLabel.textColor = DSColor.accent

        activityIndicator.hidesWhenStopped = true

        messageLabel.text = "네트워크 연결을 확인해주세요"
        messageLabel.font = DSFont.body()
        messageLabel.textColor = DSColor.textPrimary
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

        for subview in [logoLabel, activityIndicator, retryStack] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }

        NSLayoutConstraint.activate([
            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -DSSpacing.xl),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: DSSpacing.lg),
            retryStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryStack.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: DSSpacing.lg),
            retryStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: DSSpacing.md),
            retryStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -DSSpacing.md),
        ])
    }
}
