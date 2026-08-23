import AppIntents
import UIKit

/// AlarmKit stop 버튼("확인")에 실리는 인텐트 — 알람 발화 확인 감지의 유일한 훅 (Phase 13).
/// LiveActivityIntent는 앱 프로세스에서 실행된다(필요 시 시스템이 백그라운드로 깨운다).
/// 인텐트 타입은 App이 소유하고, CoreAlarm에는 인스턴스만 주입된다(App → CoreAlarm 한 방향).
///
/// 강제 종료 상태에서의 실행 여부는 실기기 잔여 검수로 판명한다 — 판명 전까지는
/// "wake 시점 리컨실(expireLocallyIfNeeded)이 커버한다"는 보수적 가정으로 진행(규약).
nonisolated struct AlarmAcknowledgeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "막차 알람 확인"
    /// 제품 결정: 심야의 "확인"은 앱을 열지 않는 것이 기본값 — 조용한 원상복귀.
    static let openAppWhenRun: Bool = false
    /// 단축어·스포트라이트 노출 불필요 — 알람 stop 버튼 전용.
    static let isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        // 조합 루트(AppDelegate 소유)의 세션 수명 서비스로 위임한다. 델리게이트 부재
        // (이론상 초기화 경합)면 조용히 no-op — 만료 리컨실이 최종 안전망이다.
        let lifecycle = await MainActor.run {
            (UIApplication.shared.delegate as? AppDelegate)?.container.alarmSessionLifecycle
        }
        await lifecycle?.alarmAcknowledged()
        return .result()
    }
}
