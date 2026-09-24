import CoreStorage
import Domain
import Foundation

/// 장소 조회 응답 캐시. `PlaceRepository`를 감싸 **호출처를 전혀 바꾸지 않고** 왕복을 줄인다
/// (피처는 여전히 Domain 프로토콜만 본다).
///
/// 캐시를 붙일 대상을 고른 기준은 **틀렸을 때의 피해**다.
///
/// | 대상 | 틀리면 | 결정 |
/// |---|---|---|
/// | 역지오코딩 | 주소 표기가 조금 낡는다 | 캐시. 좌표→주소는 행정구역 개편 수준에서만 바뀌므로 7일 |
/// | 장소 검색 | 새로 생긴 가게가 안 보인다 | 캐시. POI는 생기고 없어지므로 1시간 |
/// | 서비스 지역 판정 | **서비스가 되는데 안 된다고 막는다** | **캐시하지 않음** — 지역 확장이 즉시 반영돼야 하고, 호출 빈도도 집 주소 저장 시 1회뿐이라 아낄 게 없다 |
///
/// 실패도, **빈 결과도** 캐시하지 않는다. 지하철에서 한 번 실패한 키워드가 지상에 나와도
/// 계속 실패로 답하는 게 더 나쁘고, 빈 결과를 TTL 내내 박아 두면 원인이 사라져도 화면이
/// 회복되지 않는다.
public struct CachingPlaceRepository: PlaceRepository {
    private let upstream: any PlaceRepository
    private let geocodeCache: ExpiringCache<PlaceRecordDTO>
    private let searchCache: ExpiringCache<[PlaceRecordDTO]>

    public init(
        upstream: any PlaceRepository,
        geocodeCache: ExpiringCache<PlaceRecordDTO>,
        searchCache: ExpiringCache<[PlaceRecordDTO]>
    ) {
        self.upstream = upstream
        self.geocodeCache = geocodeCache
        self.searchCache = searchCache
    }

    public func reverseGeocode(_ coordinate: Coordinate) async throws -> Place {
        let key = Self.geocodeKey(coordinate)
        if let cached = await geocodeCache.value(forKey: key) {
            return cached.toEntity()
        }
        let place = try await upstream.reverseGeocode(coordinate)
        try? await geocodeCache.setValue(PlaceRecordDTO(place), forKey: key)
        return place
    }

    public func searchPlaces(keyword: String, near coordinate: Coordinate?) async throws -> [Place] {
        let key = Self.searchKey(keyword: keyword, near: coordinate)
        if let cached = await searchCache.value(forKey: key) {
            return cached.map { $0.toEntity() }
        }
        let places = try await upstream.searchPlaces(keyword: keyword, near: coordinate)
        // **빈 결과는 캐시하지 않는다.** 빈 배열도 성공 응답이라 그냥 담으면, 한 번 비어서
        // 온 키워드가 원인이 사라진 뒤에도 TTL 내내 비어 보인다 — 실패를 캐시하지 않는
        // 이유와 같은 이유이고, 아낄 왕복 하나보다 피해가 크다.
        if !places.isEmpty {
            try? await searchCache.setValue(places.map(PlaceRecordDTO.init), forKey: key)
        }
        return places
    }

    public func isServiceRegion(_ coordinate: Coordinate) async throws -> Bool {
        try await upstream.isServiceRegion(coordinate)
    }

    // MARK: - 키

    /// 좌표를 소수 4자리(≈11m)로 반올림한다. GPS가 가만히 있어도 미터 단위로 떨리므로
    /// 원시 좌표를 키로 쓰면 **적중률이 사실상 0**이 된다. 11m 안의 두 점이 같은 주소를
    /// 갖는다는 가정은 역지오코딩에서 안전하다.
    static func geocodeKey(_ coordinate: Coordinate) -> String {
        "\(rounded(coordinate.latitude, digits: 4)),\(rounded(coordinate.longitude, digits: 4))"
    }

    /// 검색의 좌표는 **정렬 편향(near)** 으로만 쓰이므로 3자리(≈110m)면 충분하다 —
    /// 더 잘게 쪼개면 걸어가는 동안 같은 키워드가 매번 새 키가 된다.
    static func searchKey(keyword: String, near coordinate: Coordinate?) -> String {
        let normalized = keyword
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let bias = coordinate.map {
            "\(rounded($0.latitude, digits: 3)),\(rounded($0.longitude, digits: 3))"
        } ?? "-"
        return "\(normalized)|\(bias)"
    }

    /// 문자열 보간의 기본 표기에 맡기지 않는다 — 부동소수 오차가 그대로 키에 드러나
    /// 같은 좌표가 두 키로 갈라질 수 있다.
    private static func rounded(_ value: Double, digits: Int) -> String {
        String(format: "%.\(digits)f", value)
    }
}
