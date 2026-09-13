import DesignSystem
import SnapKit
import UIKit

/// 레거시 로그인 버튼 스펙 이식: 높이 52 · radius 8 · 아이콘 leading 16(24pt) · 라벨 중앙.
/// DSButton은 아이콘을 타이틀에 인접 배치하는 Configuration 기반이라 이 스펙(아이콘
/// 고정 + 라벨 독립 중앙)에는 전용 컴포넌트가 맞다.
final class SocialLoginButton: UIButton {
    static let height: CGFloat = 52

    private let iconView = UIImageView()
    private let label = UILabel()

    init(title: String, icon: UIImage?, textColor: UIColor, background: UIColor, iconTint: UIColor) {
        super.init(frame: .zero)

        backgroundColor = background
        layer.cornerRadius = DSRadius.sm
        clipsToBounds = true

        iconView.image = icon
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = iconTint
        iconView.isUserInteractionEnabled = false

        label.attributedText = DSTypography.label1.attributed(title, color: textColor, alignment: .center)
        label.isUserInteractionEnabled = false

        addSubview(iconView)
        addSubview(label)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(DSSpacing.md)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(DSIconSize.lg)
        }
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        snp.makeConstraints { make in
            make.height.equalTo(Self.height)
        }
    }

    override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1 : 0.5 }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
