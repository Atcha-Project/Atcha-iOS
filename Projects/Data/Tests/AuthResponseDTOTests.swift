@testable import AtchaData
import CoreNetwork
import Domain
import Foundation
import Testing

struct AuthResponseDTOTests {
    @Test
    func loginResponse_decodesLegacyKeysAndMapsToEntity() throws {
        let json = Data("""
        {"id": 7, "accessToken": "SA", "refreshToken": "SR", "lat": 37.5, "lon": 127.0}
        """.utf8)

        let dto = try JSONDecoder().decode(LoginResponseDTO.self, from: json)
        let session = try dto.toEntity()

        #expect(session == LoginSession(userID: 7, accessToken: "SA", refreshToken: "SR"))
    }

    @Test
    func loginResponse_missingTokens_toEntityThrows() throws {
        let json = Data(#"{"id": 7}"#.utf8)
        let dto = try JSONDecoder().decode(LoginResponseDTO.self, from: json)

        #expect(throws: NetworkError.self) {
            _ = try dto.toEntity()
        }
    }

    @Test
    func loginResponse_missingUserID_stillMapsWithNilID() throws {
        let json = Data(#"{"accessToken": "SA", "refreshToken": "SR"}"#.utf8)
        let dto = try JSONDecoder().decode(LoginResponseDTO.self, from: json)

        #expect(try dto.toEntity().userID == nil)
    }
}
