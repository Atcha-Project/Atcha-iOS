@testable import AtchaData
import Domain
import Foundation
import Testing

struct HomeSummaryResponseDTOTests {
    @Test
    func toEntity_mapsFieldsAndDefaultsNilSubtitle() throws {
        let json = Data(#"{"id":"1","title":"막차까지 42분","subtitle":null}"#.utf8)
        let dto = try JSONDecoder().decode(HomeSummaryResponseDTO.self, from: json)
        #expect(dto.toEntity() == HomeSummary(id: "1", title: "막차까지 42분", subtitle: ""))
    }
}
