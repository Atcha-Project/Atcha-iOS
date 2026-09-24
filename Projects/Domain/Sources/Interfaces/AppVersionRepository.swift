/// 서버가 아는 최신 앱 버전 — 구현은 AtchaData(`GET /app/version`).
public protocol AppVersionRepository: Sendable {
    /// 최신 배포 버전 문자열(예: "2.0.1").
    func latestVersion() async throws -> String
}
