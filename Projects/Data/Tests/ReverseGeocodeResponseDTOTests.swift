@testable import AtchaData
import Domain
import Foundation
import Testing

struct ReverseGeocodeResponseDTOTests {
    @Test
    func toEntity_mapsCurrentLocationLabel() throws {
        let json = Data(#"{"name":"연남동","address":"서울 마포구 연남동","lat":37.560908,"lon":126.921537}"#.utf8)
        let dto = try JSONDecoder().decode(ReverseGeocodeResponseDTO.self, from: json)
        #expect(dto.toEntity() == Place(
            name: "연남동",
            address: "서울 마포구 연남동",
            coordinate: Coordinate(latitude: 37.560908, longitude: 126.921537)
        ))
    }

    @Test
    func toEntity_missingName_returnsNil() throws {
        let json = Data(#"{"address":"서울 마포구 연남동","lat":37.560908,"lon":126.921537}"#.utf8)
        let dto = try JSONDecoder().decode(ReverseGeocodeResponseDTO.self, from: json)
        #expect(dto.toEntity() == nil)
    }
}
