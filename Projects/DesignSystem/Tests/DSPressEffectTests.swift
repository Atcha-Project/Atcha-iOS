@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSPressEffectTests {
    // UIView.animate는 호스트리스에서도 모델 값을 즉시 반영한다 — 기존 테스트 규약과 동일.
    @Test
    func pressedAppliesScaleDown() {
        let view = UIView()
        DSPressEffect.setPressed(true, on: view)
        #expect(abs(view.transform.a - DSPressEffect.pressedScale) < 0.0001)
        #expect(abs(view.transform.d - DSPressEffect.pressedScale) < 0.0001)
    }

    @Test
    func releaseRestoresIdentity() {
        let view = UIView()
        DSPressEffect.setPressed(true, on: view)
        DSPressEffect.setPressed(false, on: view)
        #expect(view.transform == .identity)
    }

    // 이벤트 발화는 UIApplication이 필요하다 — 부착이 깨지지 않는 것까지만 검증하고
    // 눌림 동작 자체는 setPressed 심으로 검증한다(위 두 테스트).
    @Test
    func applyAttachesWithoutSideEffects() {
        let control = UIControl()
        DSPressEffect.apply(to: control)
        #expect(control.transform == .identity)
        #expect(control.allControlEvents.contains(.touchDown))
        #expect(control.allControlEvents.contains(.touchUpInside))
    }
}
