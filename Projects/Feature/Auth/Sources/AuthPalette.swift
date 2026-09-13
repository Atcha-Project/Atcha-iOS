import UIKit

/// 소셜 브랜드 고정색 — 테마를 타는 시맨틱 토큰이 아니라 브랜드 상수라 DSPalette에
/// 올리지 않는다(소비처가 로그인 화면뿐). 값은 레거시 colorset 실측.
enum AuthPalette {
    /// 카카오 컨테이너 배경 (#FEE500).
    static let kakaoYellow = UIColor(red: 0xFE / 255, green: 0xE5 / 255, blue: 0x00 / 255, alpha: 1)
    /// 카카오 심볼 틴트 (#181600).
    static let kakaoSymbol = UIColor(red: 0x18 / 255, green: 0x16 / 255, blue: 0x00 / 255, alpha: 1)
}
