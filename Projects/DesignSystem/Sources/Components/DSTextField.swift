import UIKit

public final class DSTextField: UIView {
    public var onTextChange: ((String) -> Void)?
    public var onSubmit: (() -> Void)?
    public var onClear: (() -> Void)?

    public var text: String { textField.text ?? "" }

    private static let fieldHeight: CGFloat = 52

    private let textField = UITextField()
    private let clearButton = UIButton(type: .system)
    private let dotView = UIView()
    private let contentStack = UIStackView()
    private let placeholder: String

    public init(placeholder: String, showsAccentDot: Bool = false) {
        self.placeholder = placeholder
        super.init(frame: .zero)

        backgroundColor = DSColor.Fill.surface
        layer.cornerRadius = DSRadius.md
        layer.borderColor = DSColor.Border.focused.cgColor

        dotView.backgroundColor = DSColor.Accent.default
        dotView.layer.cornerRadius = 2
        dotView.isHidden = !showsAccentDot
        dotView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: 4),
            dotView.heightAnchor.constraint(equalToConstant: 4),
        ])

        textField.font = DSTypography.body1.font
        textField.textColor = DSColor.Text.primary
        textField.tintColor = DSColor.Accent.default
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: DSTypography.body1.font,
                .foregroundColor: DSColor.Text.secondary,
            ]
        )
        textField.returnKeyType = .search
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.delegate = self
        textField.addAction(
            UIAction { [weak self] _ in self?.textDidChange() },
            for: .editingChanged
        )

        clearButton.setImage(DSIcon.clear16.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = DSColor.Icon.default
        clearButton.isHidden = true
        clearButton.addAction(
            UIAction { [weak self] _ in self?.handleClearTap() },
            for: .touchUpInside
        )
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            clearButton.widthAnchor.constraint(equalToConstant: DSIconSize.sm),
            clearButton.heightAnchor.constraint(equalToConstant: DSIconSize.sm),
        ])

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = DSSpacing.sm12
        contentStack.setCustomSpacing(DSSpacing.sm, after: dotView)
        [dotView, textField, clearButton].forEach(contentStack.addArrangedSubview)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.md),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.md),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.sm12),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.sm12),
        ])
    }

    public func setText(_ text: String) {
        textField.text = text
        clearButton.isHidden = text.isEmpty
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.fieldHeight)
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }

    private func textDidChange() {
        clearButton.isHidden = text.isEmpty
        onTextChange?(text)
    }

    // Internal so hostless tests can trigger the tap (sendActions needs a
    // running UIApplication).
    func handleClearTap() {
        textField.text = ""
        clearButton.isHidden = true
        onClear?()
        onTextChange?("")
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

extension DSTextField: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        layer.borderWidth = 1.5
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        layer.borderWidth = 0
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onSubmit?()
        return true
    }
}
