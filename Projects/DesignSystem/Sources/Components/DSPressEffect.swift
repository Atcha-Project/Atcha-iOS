import UIKit

/// 프레스 스케일 다운 효과 — 누르는 동안 살짝 줄었다가 떼면 복원된다.
/// 호출부 옵트인(addAction 부착)이라 기존 컴포넌트 코드는 건드리지 않는다.
public enum DSPressEffect {
    static let pressedScale: CGFloat = 0.97
    private static let duration: TimeInterval = 0.15

    /// UIControl 계열(UIButton·DSChip·커스텀 행)에 터치 이벤트로 부착한다.
    public static func apply(to control: UIControl) {
        control.addAction(
            UIAction { [weak control] _ in control.map { setPressed(true, on: $0) } },
            for: [.touchDown, .touchDragEnter]
        )
        control.addAction(
            UIAction { [weak control] _ in control.map { setPressed(false, on: $0) } },
            for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
        )
    }

    /// UIControl이 아닌 표면(셀의 setHighlighted 등)에서 직접 호출하는 심.
    public static func setPressed(_ pressed: Bool, on view: UIView) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut]
        ) {
            view.transform = pressed
                ? CGAffineTransform(scaleX: pressedScale, y: pressedScale)
                : .identity
        }
    }
}
