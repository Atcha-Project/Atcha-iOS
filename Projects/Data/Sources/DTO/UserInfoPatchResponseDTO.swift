/// 두 PATCH(`home-address`·`alert-frequency`) 공용 응답(레거시 UserInfoPatchResponse
/// 실측) — 전 필드 옵셔널. V2에 소비처가 없어 디코딩 검증 후 폐기한다.
struct UserInfoPatchResponseDTO: Decodable, Sendable {
    let id: Int?
    let providerId: String?
    let address: String?
    let lat: Double?
    let lon: Double?
}
