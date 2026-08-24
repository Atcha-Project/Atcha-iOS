import Domain
import Foundation
@preconcurrency import UserNotifications

/// UNUserNotificationCenter → Domain `LocalNotificationPort` 어댑터.
/// UserNotifications import는 App 한정(이 어댑터 + 노티 탭 라우팅 델리게이트) —
/// Feature·Domain 유입 금지 규칙은 불변.
///
/// 역할은 두 가지뿐:
/// ① 권한 요청 — 명시된 한 시점(알람 등록 성공 직후, `DefaultRegisterAlarmUseCase` 훅)에서만
///    불린다. 사일런트 푸시 경로에는 requestAuthorization이 절대 없다 — `post()`는 권한을
///    묻지 않고 현재 상태만 조회해 authorized가 아니면 조용히 no-op한다.
///    반환값(Phase 15): 이번 호출로 최초 요청이 이뤄졌고 거부됐을 때만 `deniedNow` —
///    홈이 1회 안내 토스트를 띄울 유일한 트리거다(이력이 있으면 요청도 안내도 없다).
/// ② 폴백 발송 — LA alert가 도달할 수 없는 상태(dismissed ∨ 활성 activity 없음 ∨ LA 비활성,
///    Phase 15 확대)의 변경 표출을 로컬 노티로 대신한다. 집중 모드(심야에 흔함)에서 억제되지
///    않도록 `.timeSensitive` interruptionLevel을 싣는다(time-sensitive entitlement 필요 —
///    앱 타겟 매니페스트에 선언, 유저가 설정에서 앱별로 끄는 것은 수용).
///
/// actor인 이유: LastTrainLiveActivityAdapter와 동일 — 포트가 nonisolated async 요구사항을
/// 가진 Sendable 프로토콜이라 MainActor 클래스의 격리 멤버로는 적합성이 성립하지 않는다.
/// UserNotifications 타입 일부가 Sendable 미표기라 `@preconcurrency`로 완화한다.
actor LocalNotificationAdapter: LocalNotificationPort {
    /// 권한 요청 이력 키 — 시스템 다이얼로그는 어차피 최초 1회만 뜨지만, "재요청 금지"를
    /// 명시 계약으로 어댑터가 보장한다(이력이 있으면 시스템 호출 자체를 다시 하지 않는다).
    private static let authRequestedDefaultsKey = "noti.authRequested"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - LocalNotificationPort

    @discardableResult
    func requestAuthorizationIfNeeded() async -> LocalNotificationAuthorizationOutcome {
        guard !userDefaults.bool(forKey: Self.authRequestedDefaultsKey) else {
            return .alreadySettled
        }
        // 허용·거부·에러 무관하게 "요청했음"을 기록한다 — 발송 가능 여부는 post()가 매번
        // notificationSettings()로 실시간 조회하므로 결과까지 저장할 필요가 없고,
        // 안내 토스트도 이 1회 요청의 결과(deniedNow)에만 매달리므로 구조적으로 1회다.
        userDefaults.set(true, forKey: Self.authRequestedDefaultsKey)
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            return granted ? .granted : .deniedNow
        } catch {
            // 실패 흡수(포트 계약) — 권한 요청 실패가 알람 등록 결과에 영향을 줄 수 없다.
            // 거부 "확정"이 아니므로 안내 토스트 대상도 아니다.
            return .alreadySettled
        }
    }

    func post(title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        // 권한 "요청"이 아니라 상태 조회다 — 사일런트 푸시로 깨어난 백그라운드에서도 안전.
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        // 막차 변경은 즉시 행동이 필요한 정보다 — 집중 모드를 관통한다(Phase 15).
        content.interruptionLevel = .timeSensitive
        let request = UNNotificationRequest(
            // 폴백 노티는 변경 이벤트당 1건으로 드물다 — 교체(고정 id) 없이 개별 발송.
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 즉시 발송
        )
        do {
            try await center.add(request)
        } catch {
            // 실패 흡수(포트 계약) — 표출 실패가 알람·동기화에 영향을 줄 수 없다.
        }
    }
}
