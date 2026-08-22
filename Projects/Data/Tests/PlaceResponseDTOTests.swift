@testable import AtchaData
import Domain
import Foundation
import Testing

struct PlaceResponseDTOTests {
    @Test
    func toEntity_mapsNameAddressAndCoordinate() throws {
        let json = Data(
            #"{"name":"홍대입구역","lat":37.556748,"lon":126.923643,"businessCategory":"지하철역","address":"서울 마포구","radius":"500"}"#.utf8
        )
        let dto = try JSONDecoder().decode(PlaceResponseDTO.self, from: json)
        #expect(dto.toEntity() == Place(
            name: "홍대입구역",
            address: "서울 마포구",
            coordinate: Coordinate(latitude: 37.556748, longitude: 126.923643)
        ))
    }

    @Test
    func toEntity_missingOptionalMetadata_stillReturnsPlace() throws {
        let json = Data(#"{"name":"홍대입구역","lat":37.556748,"lon":126.923643}"#.utf8)
        let dto = try JSONDecoder().decode(PlaceResponseDTO.self, from: json)
        #expect(dto.toEntity() == Place(
            name: "홍대입구역",
            address: "",
            coordinate: Coordinate(latitude: 37.556748, longitude: 126.923643)
        ))
    }

    @Test
    func toEntity_missingCoordinate_returnsNil() throws {
        let json = Data(#"{"name":"홍대입구역"}"#.utf8)
        let dto = try JSONDecoder().decode(PlaceResponseDTO.self, from: json)
        #expect(dto.toEntity() == nil)
    }
}
