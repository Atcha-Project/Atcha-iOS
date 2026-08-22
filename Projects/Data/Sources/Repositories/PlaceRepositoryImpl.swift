import CoreNetwork
import Domain

public struct PlaceRepositoryImpl: PlaceRepository {
    private let networkClient: any NetworkClient

    public init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    public func searchPlaces(keyword: String, near coordinate: Coordinate?) async throws -> [Place] {
        let dtos: [PlaceResponseDTO] = try await networkClient.requestEnveloped(
            PlaceEndpoint.search(keyword: keyword, near: coordinate)
        )
        return dtos.compactMap { $0.toEntity() }
    }

    public func reverseGeocode(_ coordinate: Coordinate) async throws -> Place {
        let dto: ReverseGeocodeResponseDTO = try await networkClient.requestEnveloped(
            PlaceEndpoint.reverseGeocode(coordinate)
        )
        guard let place = dto.toEntity() else {
            throw NetworkError.decoding(underlying: MissingResultError())
        }
        return place
    }
}
