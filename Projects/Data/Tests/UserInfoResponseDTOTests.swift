@testable import AtchaData
import Foundation
import Testing

struct UserInfoResponseDTOTests {
    /// 레거시 실측 키 핀: 좌표는 "lat"/"lon", appVersion만 비옵셔널.
    @Test
    func decode_fullPayload_mapsToEntityWithCoordinate() throws {
        let json = Data("""
        {
            "id": 7,
            "providerId": "kakao_123",
            "nickname": "곤",
            "profileUrl": "https://example.com/p.png",
            "address": "서울 어딘가 1-2",
            "lat": 37.5,
            "lon": 127.0,
            "appVersion": "2.0.0"
        }
        """.utf8)

        let dto = try JSONDecoder().decode(UserInfoResponseDTO.self, from: json)
        let entity = dto.toEntity()

        #expect(entity.userID == 7)
        #expect(entity.providerID == "kakao_123")
        #expect(entity.nickname == "곤")
        #expect(entity.address == "서울 어딘가 1-2")
        #expect(entity.coordinate?.latitude == 37.5)
        #expect(entity.coordinate?.longitude == 127.0)
        #expect(entity.appVersion == "2.0.0")
    }

    /// 좌표는 lat·lon이 모두 있을 때만 성립한다(레거시 toEntity 규칙).
    @Test
    func decode_missingLon_dropsCoordinate() throws {
        let json = Data("""
        { "lat": 37.5, "appVersion": "2.0.0" }
        """.utf8)

        let dto = try JSONDecoder().decode(UserInfoResponseDTO.self, from: json)

        #expect(dto.toEntity().coordinate == nil)
    }

    /// 두 PATCH 공용 응답 — 전 필드 옵셔널이라 빈 객체도 디코딩된다.
    @Test
    func patchResponse_decodesEmptyObject() throws {
        let dto = try JSONDecoder().decode(
            UserInfoPatchResponseDTO.self, from: Data("{}".utf8)
        )

        #expect(dto.id == nil)
        #expect(dto.address == nil)
    }
}
