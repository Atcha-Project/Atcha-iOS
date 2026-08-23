import UIKit

/// 컴팩트 pill 칩 — 최근 경로 원탭(Phase 18)처럼 내용이 데이터를 따라 바뀌는 표면용.
/// DSButton은 title이 init 고정이라(홈의 등록/해제 버튼 2개 우회가 그 기록) 동적
/// 텍스트 자리에 부적합하다 — setText 갱신 가능이 이 컴포넌트의 존재 이유다.
public final class DSChip: UIButton {
    private static let height: CGFloat = 32

    public init() {
        super.init(frame: .zero)

        var configuration = UIButton.Configuration.filled()
        // 높이 절반 = pill. DSRadius.lg(16)가 그 값과 일치한다.
        configuration.background.cornerRadius = DSRadius.lg
        configuration.cornerStyle = .fixed
        configuration.contentInsets = .init(
            top: 0, leading: DSSpacing.md, bottom: 0, trailing: DSSpacing.md
        )
        // Colors are applied eagerly so the initial configuration is complete
        // without waiting for an update pass (which never runs in hostless
        // tests); the update handler keeps them in sync with state changes.
        Self.applyColors(&configuration, isEnabled: true)
        self.configuration = configuration

        configurationUpdateHandler = { button in
            guard var configuration = button.configuration else { return }
            Self.applyColors(&configuration, isEnabled: button.isEnabled)
            button.configuration = configuration
        }
    }

    public func setText(_ text: String) {
        configuration?.attributedTitle = AttributedString(
            text, attributes: AttributeContainer([.font: DSTypography.label2.font])
        )
    }

    static func applyColors(_ configuration: inout UIButton.Configuration, isEnabled: Bool) {
        // secondary 계열 매핑(DSButton.secondary와 동일 척도) — 강조가 아니라 보조 진입점이다.
        configuration.baseBackgroundColor = isEnabled ? DSColor.Fill.elevated : DSColor.Fill.surface
        configuration.baseForegroundColor = isEnabled ? DSColor.Text.primary : DSColor.Text.disabled
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: super.intrinsicContentSize.width, height: Self.height)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
