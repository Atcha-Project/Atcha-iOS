// 레거시 서버 envelope 실측: { "responseCode": "SUCCESS", "result": ... }
struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let responseCode: String
    let result: T?
}

/// result가 없는(무시되는) 응답을 기대할 때 쓰는 자리표시 타입.
struct APIEmptyResult: Decodable, Sendable {}

/// 실패 응답 본문 실측: { "responseCode": ..., "message": ..., "path": ... }
struct APIFailureResponse: Decodable, Sendable {
    let responseCode: String?
    let message: String?
}

/// envelope는 성공인데 기대한 result가 없거나 엔티티로 세울 수 없을 때.
struct MissingResultError: Error, Sendable {}
