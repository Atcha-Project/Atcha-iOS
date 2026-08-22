import UIKit

public final class DSToast: UIView {
    public struct Action {
        public let title: String
        public let handler: () -> Void

        public init(title: String, handler: @escaping () -> Void) {
            self.title = title
            self.handler = handler
        }
    }

    private static weak var current: DSToast?

    private let messageLabel = UILabel()
    private let actionLabel = UILabel()
    private let action: Action?
    private var autoHideTask: Task<Void, Never>?

    public init(message: String, action: Action? = nil) {
        self.action = action
        super.init(frame: .zero)

        backgroundColor = DSColor.Fill.elevated
        layer.cornerRadius = DSRadius.lg

        messageLabel.attributedText = DSTypography.body2.attributed(
            message, color: DSColor.Text.primary
        )
        messageLabel.numberOfLines = 0

        let contentStack = UIStackView(arrangedSubviews: [messageLabel])
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = DSSpacing.sm

        if let action {
            actionLabel.attributedText = DSTypography.body2.attributed(
                action.title, color: DSColor.Accent.default
            )
            actionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            contentStack.addArrangedSubview(actionLabel)
            addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(didTapAction))
            )
        }

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.md),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.md),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.md),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.md),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
        ])
    }

    @discardableResult
    public static func show(
        _ message: String,
        in view: UIView,
        action: Action? = nil,
        duration: TimeInterval = 2.0
    ) -> DSToast {
        current?.dismiss(animated: false)
        let toast = DSToast(message: message, action: action)
        toast.show(in: view, duration: duration)
        current = toast
        return toast
    }

    public func show(in view: UIView, duration: TimeInterval = 2.0) {
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DSSpacing.md),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DSSpacing.md),
            bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -DSSpacing.md
            ),
        ])

        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 10)
        UIView.animate(
            withDuration: 0.4, delay: 0,
            usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5,
            options: [.beginFromCurrentState, .allowUserInteraction]
        ) {
            self.alpha = 1
            self.transform = .identity
        }

        // [weak self] keeps a removed toast from pinning itself alive until
        // the timer fires; no deinit cancellation needed.
        autoHideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    public func dismiss(animated: Bool = true) {
        autoHideTask?.cancel()
        autoHideTask = nil
        guard animated else {
            removeFromSuperview()
            return
        }
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn]) {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: 10)
        } completion: { _ in
            self.removeFromSuperview()
        }
    }

    @objc private func didTapAction() {
        handleActionTap()
    }

    // Internal so hostless tests can trigger the tap (gesture recognizers
    // don't fire without a running UIApplication).
    func handleActionTap() {
        action?.handler()
        dismiss()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
