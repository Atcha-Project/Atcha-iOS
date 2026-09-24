/// PUT /members/me 요청 — 서버가 users.fcm_token을 갱신한다(알람 등록 시 이 값을 복사해 푸시).
struct FcmTokenUpdateRequestDTO: Encodable, Sendable {
    let fcmToken: String
}
