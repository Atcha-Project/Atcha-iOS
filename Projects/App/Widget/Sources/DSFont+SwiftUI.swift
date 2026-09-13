import DesignSystem
import SwiftUI
import UIKit

// DSColor+SwiftUI와 같은 독트린 — 브리지는 위젯에 두고 DesignSystem에는
// SwiftUI 의존을 더하지 않는다.
extension Font {
    /// DesignSystem Pretendard를 SwiftUI로 브리지한다,
    /// e.g. `Font.pretendard(.bold, size: 38)`.
    /// DSFont.pretendard가 최초 호출 시 once-가드 등록을 수행하고, 번들·등록
    /// 실패 시 같은 가중치의 시스템 폰트로 폴백한다 — Font.custom을 쓰지 않는
    /// 이유(커스텀 이름 실패 시 weight를 잃은 시스템 regular로 떨어진다).
    static func pretendard(_ weight: DSFont.Weight, size: CGFloat) -> Font {
        // UIFont ↔ CTFont는 톨프리 브리지 — SwiftUI 공개 API Font(_: CTFont)로 감싼다.
        Font(DSFont.pretendard(weight, size: size) as CTFont)
    }
}
