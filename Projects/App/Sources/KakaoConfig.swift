import Foundation

/// 카카오 네이티브 앱 키 — Tuist env(TUIST_KAKAO_APP_KEY)가 Info.plist로 주입한 값을
/// 읽는다(xcconfig 금지 규약). 미주입(빈 값)이면 nil — 카카오 로그인만 비활성.
enum KakaoConfig {
    static var appKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "KAKAO_APP_KEY") as? String,
              !key.isEmpty
        else { return nil }
        return key
    }
}
