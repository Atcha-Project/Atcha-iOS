/// POST /auth/guest 요청(제안 계약) — 서버 합의 전까지 필드명은 가안이다.
struct GuestSessionRequestDTO: Encodable, Sendable {
    let deviceId: String
    let fcmToken: String?
}
