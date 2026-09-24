/// `DELETE /members/me` body(레거시 WithdrawRequest 실측).
struct WithdrawRequestDTO: Encodable, Sendable {
    let reason: String?
}
