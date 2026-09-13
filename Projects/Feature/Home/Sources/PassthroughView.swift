import UIKit

/// 토스트 전용 오버레이 호스트 — 서브뷰(토스트)에 명중할 때만 터치를 소비하고
/// 그 외 영역은 아래 계층(스크롤·하단 CTA)으로 통과시킨다.
final class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view === self ? nil : view
    }
}
