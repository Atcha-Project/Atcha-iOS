/// `PATCH /members/me/alert-frequency` body(레거시 PushAlarmPatchRequest 실측).
struct AlertFrequencyPatchRequestDTO: Encodable, Sendable {
    let alertFrequencies: [Int]?
}
