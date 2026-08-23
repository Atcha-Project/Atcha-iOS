import UIKit

// Countdown banner ("출발까지 N분"). Rendering only — the 1-minute tick
// lives in the owning ViewModel, which calls configure on each update.
public final class DSBanner: UIView {
    /// 긴급도 3단계에 대응한다: 여유(normal) → 주의(caution) → 임박(urgent).
    /// 시각 위계도 같은 순서로 상승한다 — 라임 컨테이너 → 레드 컨테이너 → 레드 솔리드.
    public enum Style {
        case normal
        case caution
        case urgent
    }

    private let label = UILabel()

    public init(text: String = "", style: Style = .normal) {
        super.init(frame: .zero)

        layer.cornerRadius = DSRadius.lg

        label.font = DSTypography.label1.font
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.md),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.md),
            label.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.sm12),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.sm12),
        ])

        configure(text: text, style: style)
    }

    public func configure(text: String, style: Style = .normal) {
        label.text = text
        switch style {
        case .normal:
            backgroundColor = DSColor.Accent.container
            label.textColor = DSColor.Accent.default
        case .caution:
            backgroundColor = DSColor.State.dangerContainer
            label.textColor = DSColor.State.danger
        case .urgent:
            backgroundColor = DSColor.State.urgent
            label.textColor = DSColor.Text.primary
        }
    }

    /// 갱신 강조 — 값이 바뀐 순간 1회 펄스로 시선을 끈다("막차가 당겨졌어요" 등).
    /// 텍스트·스타일은 건드리지 않으므로 configure와 어느 순서로 불러도 안전하다.
    public func emphasize() {
        UIView.animate(
            withDuration: 0.15, delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            self.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        } completion: { _ in
            UIView.animate(
                withDuration: 0.4, delay: 0,
                usingSpringWithDamping: 0.5, initialSpringVelocity: 0,
                options: [.beginFromCurrentState, .allowUserInteraction]
            ) {
                self.transform = .identity
            }
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
