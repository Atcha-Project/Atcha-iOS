/// `POST /auth/guest` body. fcmToken은 알림 권한이 아직 없으면 부재가 정상이라
/// 빈 문자열로 강등하지 않고 키를 생략한다(서버 계약상 optional).
struct GuestAuthRequestDTO: Encodable, Sendable {
    let deviceId: String
    let fcmToken: String?
}
