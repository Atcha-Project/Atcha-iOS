import DesignSystem
import SnapKit
import UIKit

/// 홈의 출발/도착 행 — 편집이 아니라 검색 진입 트리거다. DSGroupedCard 안에
/// DSTextField를 넣으면 surface 위 surface 중첩이 되므로 카드 행에 맞는 평면
/// 행으로 대체한다. 텍스트 규약은 DSTextField와 동일: 빈 값이면 placeholder가
/// 유도 문구 역할을 한다. 우측 셰브런이 "탭하면 검색으로 이동"을 시사한다.
final class HomeFieldRow: UIControl {
    private static let height: CGFloat = 56

    private let placeholder: String
    private let textLabel = UILabel()

    init(icon: UIImage, placeholder: String, showsAccentDot: Bool = false) {
        self.placeholder = placeholder
        super.init(frame: .zero)

        let iconView = UIImageView(image: icon)
        iconView.tintColor = DSColor.Icon.default
        iconView.contentMode = .scaleAspectFit

        let chevronView = UIImageView(image: DSIcon.chevronRight16)
        chevronView.tintColor = DSColor.Icon.muted
        chevronView.contentMode = .scaleAspectFit

        textLabel.font = DSTypography.body1.font

        [iconView, textLabel, chevronView].forEach(addSubview)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(DSSpacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(DSIconSize.lg)
        }

        let textLeading: ConstraintItem
        if showsAccentDot {
            let dot = UIView()
            dot.backgroundColor = DSColor.Accent.default
            dot.layer.cornerRadius = 2
            addSubview(dot)
            dot.snp.makeConstraints { make in
                make.leading.equalTo(iconView.snp.trailing).offset(DSSpacing.sm)
                make.centerY.equalToSuperview()
                make.size.equalTo(4)
            }
            textLeading = dot.snp.trailing
        } else {
            textLeading = iconView.snp.trailing
        }
        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(textLeading).offset(DSSpacing.sm)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(chevronView.snp.leading).offset(-DSSpacing.sm)
        }
        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(DSSpacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(DSIconSize.sm)
        }
        snp.makeConstraints { make in
            make.height.equalTo(Self.height)
        }

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = placeholder
        setText("")
    }

    func setText(_ text: String) {
        if text.isEmpty {
            textLabel.text = placeholder
            textLabel.textColor = DSColor.Text.secondary
            accessibilityValue = nil
        } else {
            textLabel.text = text
            textLabel.textColor = DSColor.Text.primary
            accessibilityValue = text
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
