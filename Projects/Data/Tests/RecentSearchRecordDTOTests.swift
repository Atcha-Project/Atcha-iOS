@testable import AtchaData
import Domain
import Foundation
import Testing

struct RecentSearchRecordDTOTests {
    @Test
    func decode_inlineJSON_mapsFields() throws {
        let json = Data(
            #"{"name":"홍대입구역","address":"서울 마포구","latitude":37.556748,"longitude":126.923643}"#.utf8
        )
        let dto = try JSONDecoder().decode(RecentSearchRecordDTO.self, from: json)
        #expect(dto.toEntity() == Place(
            name: "홍대입구역",
            address: "서울 마포구",
            coordinate: Coordinate(latitude: 37.556748, longitude: 126.923643)
        ))
    }

    @Test
    func roundTrip_placeToRecordToEntity_preservesFields() throws {
        let place = Place(
            name: "서울역",
            address: "서울 용산구",
            coordinate: Coordinate(latitude: 37.554722, longitude: 126.970833)
        )
        let encoded = try JSONEncoder().encode(RecentSearchRecordDTO(place))
        let decoded = try JSONDecoder().decode(RecentSearchRecordDTO.self, from: encoded)
        #expect(decoded.toEntity() == place)
    }
}
