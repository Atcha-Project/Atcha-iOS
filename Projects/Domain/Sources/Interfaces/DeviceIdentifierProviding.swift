/// 디바이스 식별자 포트 — `POST /auth/guest`의 deviceId 소싱용.
/// 게스트 계정의 유일한 신원이므로 **같은 기기에서 항상 같은 값**이어야 한다
/// (서버 계약: 토큰이 모두 죽어도 같은 deviceId로 /auth/guest를 부르면 같은 계정이 돌아온다).
/// 구현은 App 어댑터 — IDFV는 앱 전체 삭제 시 바뀌므로 그대로 쓰지 않는다.
public protocol DeviceIdentifierProviding: Sendable {
    func currentDeviceID() async -> String
}
