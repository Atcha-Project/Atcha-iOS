@testable import Domain
import Foundation
import Testing

private struct StubError: Error {}

private actor CallLog {
    private(set) var coordinates: [Coordinate] = []
    func append(_ coordinate: Coordinate) { coordinates.append(coordinate) }
}

private struct SpyPlaceRepository: PlaceRepository {
    let log: CallLog
    var place: Place? = nil

    func searchPlaces(keyword: String, near coordinate: Coordinate?) async throws -> [Place] {
        []
    }

    func reverseGeocode(_ coordinate: Coordinate) async throws -> Place {
        await log.append(coordinate)
        guard let place else { throw StubError() }
        return place
    }
}

struct DefaultReverseGeocodeUseCaseTests {
    @Test
    func execute_forwardsCoordinateAndReturnsPlace() async throws {
        let log = CallLog()
        let expected = Place(
            name: "강남역",
            address: "서울 강남구 강남대로 396",
            coordinate: Coordinate(latitude: 37.4979, longitude: 127.0276)
        )
        let sut = DefaultReverseGeocodeUseCase(
            repository: SpyPlaceRepository(log: log, place: expected)
        )

        let place = try await sut.execute(
            coordinate: Coordinate(latitude: 37.4979, longitude: 127.0276)
        )

        #expect(place == expected)
        #expect(await log.coordinates == [Coordinate(latitude: 37.4979, longitude: 127.0276)])
    }

    @Test
    func execute_propagatesRepositoryError() async {
        let sut = DefaultReverseGeocodeUseCase(
            repository: SpyPlaceRepository(log: CallLog())
        )

        await #expect(throws: StubError.self) {
            _ = try await sut.execute(coordinate: Coordinate(latitude: 0, longitude: 0))
        }
    }
}
