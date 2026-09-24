/// 게스트 계정의 키 — 앱 재설치 후에도 같은 값이어야 같은 게스트 회원으로 이어진다.
/// 구현은 App 어댑터(키체인 보관 UUID).
public protocol DeviceIdentifierProviding: Sendable {
    func deviceID() throws -> String
}
