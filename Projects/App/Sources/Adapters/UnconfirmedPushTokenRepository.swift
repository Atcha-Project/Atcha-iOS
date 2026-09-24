import Domain
import os

/// FCM 토큰 갱신 API가 서버에서 확정되기 전(미확정 #5)의 자리표시 — 호출 지점과 중복 방지는
/// 지금 배선해 두고, 경로가 정해지면 AtchaData의 실구현으로 이 타입만 교체한다.
struct UnconfirmedPushTokenRepository: PushTokenRepository {
    private static let logger = Logger(subsystem: "com.atcha.iOS.v2", category: "FCM")

    func register(token: String) async throws {
        Self.logger.info("FCM 토큰 서버 전달 보류(API 미확정): \(token, privacy: .private)")
    }
}
