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
    /// 신선도 스탬프("HH:mm 확인 기준") 등 본문에 딸린 보조 라인 — nil이면 기존 렌더와 동일.
    private let detailLabel = UILabel()
    private let textStack = UIStackView()

    public init(text: String = "", style: Style = .normal) {
        super.init(frame: .zero)

        layer.cornerRadius = DSRadius.lg

        label.font = DSTypography.label1.font
        label.textAlignment = .center
        detailLabel.font = DSTypography.caption2.font
        detailLabel.textAlignment = .center
        detailLabel.isHidden = true

        textStack.axis = .vertical
        textStack.alignment = .center
        textStack.spacing = DSSpacing.xxs
        [label, detailLabel].forEach(textStack.addArrangedSubview)
        textStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textStack)
        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.md),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.md),
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.sm12),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.sm12),
        ])

        configure(text: text, style: style)
    }

    public func configure(text: String, style: Style = .normal, detailText: String? = nil) {
        label.text = text
        detailLabel.text = detailText
        detailLabel.isHidden = detailText == nil
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
        // 보조 라인은 본문과 같은 토큰 색의 감쇠 톤 — 스타일별 배경(컨테이너/솔리드)
        // 어디서든 본문보다 한 단계 낮은 위계를 유지한다(DSRouteCard legs alpha 관례).
        detailLabel.textColor = label.textColor.withAlphaComponent(0.72)
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
