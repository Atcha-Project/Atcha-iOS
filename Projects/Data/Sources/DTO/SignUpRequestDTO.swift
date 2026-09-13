/// `POST /auth/sign-up` body(레거시 OnboardingDTO.SignUpRequest 실측).
/// 응답은 `/auth/login`과 계약이 같아 `LoginResponseDTO`를 재사용한다.
struct SignUpRequestDTO: Encodable, Sendable {
    let provider: Int
    let userName: String?
    let address: String
    let lat: Double
    let lon: Double
    let alertFrequencies: [Int]
    /// 레거시 실측: FCM 토큰 부재 시 빈 문자열 전송.
    let fcmToken: String
}
