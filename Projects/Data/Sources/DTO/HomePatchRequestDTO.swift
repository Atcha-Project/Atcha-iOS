/// `PATCH /members/me/home-address` body(레거시 HomePatchRequest 실측).
struct HomePatchRequestDTO: Encodable, Sendable {
    let address: String?
    let lat: Double?
    let lon: Double?
}
