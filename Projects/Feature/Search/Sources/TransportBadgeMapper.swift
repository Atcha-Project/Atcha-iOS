import DesignSystem
import Domain

/// Domain 이동수단 → DesignSystem 배지 어휘. `DSTransportBadge.Kind`는 의도적으로
/// Domain 타입이 아니라, 이 번역은 피처에 산다.
///
/// 노선명 문자열 파싱(버스 종류·지하철 노선 테이블)은 팔레트와 짝이라 DesignSystem이
/// 들고 있다 — 여기 남은 건 `leg.mode` 분기뿐이다.
enum TransportBadgeMapper {
    static func kinds(for legs: [TransportLeg]) -> [DSTransportBadge.Kind] {
        legs.map(kind(for:))
    }

    static func kind(for leg: TransportLeg) -> DSTransportBadge.Kind {
        switch leg.mode {
        case .walk:
            .walk
        case .bus:
            .bus(legacyRouteName: leg.routeName)
        case .subway:
            .subway(routeName: leg.routeName)
        case .unknown:
            .bus(.general, text: leg.routeName ?? "이동")
        }
    }
}
