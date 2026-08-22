@testable import AtchaData
import Domain
import Foundation
import Testing

struct AlarmRefreshResponseDTOTests {
    @Test
    func toEntity_mapsFieldsAndParsesIsRealString() throws {
        let json = Data(
            #"{"departureTime":"2026-08-22T23:40:00","updatedAt":"2026-08-22T22:00:00","lastRouteId":"route-1","isReal":"true"}"#.utf8
        )
        let dto = try JSONDecoder().decode(AlarmRefreshResponseDTO.self, from: json)
        let info = try #require(dto.toEntity())
        #expect(info.lastRouteId == "route-1")
        #expect(info.isReal)
        #expect(info.departureTime != nil)
        #expect(info.updatedAt != nil)
    }

    @Test
    func toEntity_isRealFalseOrMissing_mapsToFalse() throws {
        for fixture in [#"{"lastRouteId":"r","isReal":"false"}"#, #"{"lastRouteId":"r"}"#] {
            let dto = try JSONDecoder().decode(AlarmRefreshResponseDTO.self, from: Data(fixture.utf8))
            #expect(dto.toEntity()?.isReal == false)
        }
    }

    @Test
    func toEntity_missingLastRouteId_returnsNil() throws {
        let dto = try JSONDecoder().decode(AlarmRefreshResponseDTO.self, from: Data(#"{"isReal":"true"}"#.utf8))
        #expect(dto.toEntity() == nil)
    }
}
