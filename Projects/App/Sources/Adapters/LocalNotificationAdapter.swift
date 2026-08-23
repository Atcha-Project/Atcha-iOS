import Domain
import Foundation
@preconcurrency import UserNotifications

/// UNUserNotificationCenter → Domain `LocalNotificationPort` 어댑터.
/// UserNotifications를 import하는 곳은 App에서 이 파일뿐(디바이스 프레임워크 App 한정 규칙).
///
/// 역할은 Phase 12의 두 가지뿐:
/// ① 권한 요청 — 명시된 한 시점(알람 등록 성공 직후, `DefaultRegisterAlarmUseCase` 훅)에서만
///    불린다. 사일런트 푸시 경로에는 requestAuthorization이 절대 없다 — `post()`는 권한을
///    묻지 않고 현재 상태만 조회해 authorized가 아니면 조용히 no-op한다.
/// ② dismiss 폴백 발송 — 유저가 LA를 스와이프로 지운 뒤의 변경 표출을 로컬 노티로 대신한다.
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

    func requestAuthorizationIfNeeded() async {
        guard !userDefaults.bool(forKey: Self.authRequestedDefaultsKey) else { return }
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            // 실패 흡수(포트 계약) — 권한 요청 실패가 알람 등록 결과에 영향을 줄 수 없다.
        }
        // 허용·거부·에러 무관하게 "요청했음"만 기록한다 — 발송 가능 여부는 post()가 매번
        // notificationSettings()로 실시간 조회하므로 결과까지 저장할 필요가 없다.
        userDefaults.set(true, forKey: Self.authRequestedDefaultsKey)
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
