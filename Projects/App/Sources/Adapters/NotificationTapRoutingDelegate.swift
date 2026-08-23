import Foundation
@preconcurrency import UserNotifications

/// UNUserNotificationCenter 델리게이트 (Phase 15) — 포그라운드 표시 정책과 노티 탭 라우팅.
/// UserNotifications import는 App 한정(LocalNotificationAdapter + 이 파일) — Feature·Domain
/// 유입 금지 규칙은 불변. 이 앱의 노티는 폴백 노티 하나뿐이라 payload 파싱·identifier 분기가 없다.
///
/// 클래스는 App 기본 격리(MainActor)를 그대로 쓴다 — 시스템이 부르는 델리게이트 메서드만
/// nonisolated witness로 두고 내부에서 메인 액터로 복귀한다.
final class NotificationTapRoutingDelegate: NSObject, UNUserNotificationCenterDelegate {
    /// 노티 탭 → 홈 랜딩 훅 — SceneDelegate가 AppCoordinator.returnToHome()으로 배선한다.
    /// 앱 종료 상태에서의 탭(훅 미배선 시점)은 버린다 — 스플래시 → 홈이 곧 랜딩이라 의미가 같다.
    var onTap: (() -> Void)?

    /// AppDelegate launch 완료 전에 호출해야 한다 — 탭이 앱을 cold start시키는 경우의
    /// didReceive까지 시스템이 이 델리게이트로 전달한다. UN 타입을 노출하지 않는 등록
    /// 메서드라 AppDelegate에 UserNotifications import가 생기지 않는다.
    func attachToNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// 포그라운드 표시 정책 명시(Phase 15 결정): 표출 분기가 applicationState를 선행 검사해
    /// 포그라운드에서는 애초에 노티를 발송하지 않는 것이 1차 방어라 이중 알림은 구조적으로
    /// 없다. 이 정책은 "백그라운드 발송 → 활성화 직후 도달" 경합에서 인앱 토스트가 이미
    /// 지나갔을 때 유일한 가시 채널을 살리는 안전망이다.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // 기본 탭만 라우팅한다 — 커스텀 액션·dismiss 액션은 없다(만들지도 않았다).
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        await MainActor.run { self.onTap?() }
    }
}
