@testable import AtchaData
import Domain
import Foundation
import Testing

struct LastRouteResponseDTOTests {
    @Test
    func toEntity_mapsLegacyShapedResponse() throws {
        let json = Data(#"""
        {
            "routeId": "route-1",
            "departureDateTime": "2026-08-22T23:40:00",
            "totalTime": 2820,
            "totalWalkTime": 600,
            "transferCount": 1,
            "totalDistance": 12000,
            "totalWalkDistance": 800,
            "pathType": 1,
            "legs": [
                {
                    "distance": 300,
                    "sectionTime": 240,
                    "mode": "WALK",
                    "start": {"name": "강남역", "lon": 127.02761, "lat": 37.49794},
                    "end": {"name": "서울역", "lon": 126.970833, "lat": 37.554722}
                },
                {
                    "sectionTime": 1800,
                    "mode": "SUBWAY",
                    "departureDateTime": "2026-08-22T23:45:00",
                    "route": "수도권2호선",
                    "type": "2",
                    "subwayFinalStation": "성수",
                    "subwayDirection": "내선",
                    "isExpressSubway": false,
                    "isLastSubway": true
                }
            ]
        }
        """#.utf8)

        let dto = try JSONDecoder().decode(LastRouteResponseDTO.self, from: json)
        let route = try #require(dto.toEntity())

        #expect(route.id == "route-1")
        #expect(route.departureTime == Self.kstDate(2026, 8, 22, 23, 40))
        #expect(route.totalTime == 2820)
        #expect(route.totalWalkTime == 600)
        #expect(route.transferCount == 1)
        #expect(route.legs.count == 2)
        #expect(route.legs[0].mode == .walk)
        #expect(route.legs[0].start == RoutePoint(
            name: "강남역",
            coordinate: Coordinate(latitude: 37.49794, longitude: 127.02761)
        ))
        #expect(route.legs[1].mode == .subway)
        #expect(route.legs[1].departureTime == Self.kstDate(2026, 8, 22, 23, 45))
        #expect(route.legs[1].routeName == "수도권2호선")
        #expect(route.legs[1].subwayFinalStation == "성수")
        #expect(route.legs[1].isLastSubway)
        #expect(!route.legs[1].isExpressSubway)
    }

    @Test
    func toEntity_unknownMode_fallsBackToUnknown() throws {
        let json = Data(#"{"routeId":"r","departureDateTime":"2026-08-22T23:40:00","legs":[{"mode":"TRAM"}]}"#.utf8)
        let dto = try JSONDecoder().decode(LastRouteResponseDTO.self, from: json)
        #expect(dto.toEntity()?.legs.first?.mode == .unknown)
    }

    @Test
    func toEntity_missingRouteId_returnsNil() throws {
        let json = Data(#"{"departureDateTime":"2026-08-22T23:40:00"}"#.utf8)
        let dto = try JSONDecoder().decode(LastRouteResponseDTO.self, from: json)
        #expect(dto.toEntity() == nil)
    }

    @Test
    func toEntity_unparsableDepartureDateTime_returnsNil() throws {
        let json = Data(#"{"routeId":"r","departureDateTime":"not-a-date"}"#.utf8)
        let dto = try JSONDecoder().decode(LastRouteResponseDTO.self, from: json)
        #expect(dto.toEntity() == nil)
    }

    private static func kstDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
