import CoreNetwork
import Domain

public struct AlarmRepositoryImpl: AlarmRepository {
    private let networkClient: any NetworkClient

    public init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    public func register(lastRouteId: String) async throws {
        let _: APIEmptyResult = try await networkClient.requestEnveloped(
            AlarmEndpoint.register(AlarmRegisterRequestDTO(lastRouteId: lastRouteId))
        )
    }

    public func cancel(lastRouteId: String) async throws {
        let _: APIEmptyResult = try await networkClient.requestEnveloped(
            AlarmEndpoint.cancel(lastRouteId: lastRouteId)
        )
    }

    /// 서버는 "등록된 알람 없음"을 **404 + `URT_001`** 로 알린다(2026-09-25 실측:
    /// `{"responseCode":"URT_001","message":"id(1010) 유저가 등록한 경로를 찾을 수 없습니다."}`).
    /// 이걸 throw로 흘리면 조회 실패와 구분되지 않아, 서버가 세션을 잃어도 앱이 낡은
    /// 세션을 계속 붙들고 평상시엔 매 실행마다 에러 로그가 남는다.
    public func refresh() async throws -> AlarmRefreshOutcome {
        do {
            let dto: AlarmRefreshResponseDTO = try await networkClient.requestEnveloped(
                AlarmEndpoint.refresh
            )
            guard let info = dto.toEntity() else {
                throw NetworkError.decoding(underlying: MissingResultError())
            }
            return .registered(info)
        } catch let error as ServerError where error.code == Self.notRegisteredCode {
            return .notRegistered
        }
    }

    /// 서버가 "이 유저에게 등록된 경로가 없다"를 나타내는 responseCode.
    private static let notRegisteredCode = "URT_001"
}
