import DesignSystem
import Domain

/// Maps Domain transit legs onto the DesignSystem's badge vocabulary.
/// DSTransportBadge.Kind is deliberately not a Domain type, so this
/// translation lives in the feature.
enum TransportBadgeMapper {
    static func kinds(for legs: [TransportLeg]) -> [DSTransportBadge.Kind] {
        legs.map(kind(for:))
    }

    static func kind(for leg: TransportLeg) -> DSTransportBadge.Kind {
        switch leg.mode {
        case .walk:
            .walk
        case .bus:
            busKind(routeName: leg.routeName)
        case .subway:
            subwayKind(routeName: leg.routeName)
        case .unknown:
            .bus(.general, text: leg.routeName ?? "이동")
        }
    }

    // Legacy server format: "간선:472" (type:number).
    private static func busKind(routeName: String?) -> DSTransportBadge.Kind {
        guard let routeName, let colonIndex = routeName.firstIndex(of: ":") else {
            return .bus(.general, text: routeName ?? "버스")
        }
        let type = String(routeName[..<colonIndex])
        let number = String(routeName[routeName.index(after: colonIndex)...])
        let busType: DSBusType = switch type {
        case "간선": .mainline
        case "지선": .regular
        case "마을": .town
        case "광역", "직행": .widearea
        default: .general
        }
        return .bus(busType, text: number)
    }

    // Ordered so distinctive names win before the bare "N호선" patterns
    // ("인천 1호선" must not fall through to "1호선").
    private static let subwayLineTable: [(keyword: String, line: DSSubwayLine, badge: String)] = [
        ("수인분당", .suinBundang, "수인분당"),
        ("신분당", .shinbundang, "신분당"),
        ("경의중앙", .gyeonguiJungang, "경의중앙"),
        ("경춘", .gyeongchun, "경춘"),
        ("경강", .gyeonggang, "경강"),
        ("공항", .airport, "공항"),
        ("GTX", .gtxA, "GTX-A"),
        ("인천 1", .incheon1, "인천1"),
        ("인천1", .incheon1, "인천1"),
        ("인천 2", .incheon2, "인천2"),
        ("인천2", .incheon2, "인천2"),
        ("서해", .seohae, "서해"),
        ("신림", .sillim, "신림"),
        ("우이신설", .uiSinseol, "우이신설"),
        ("의정부", .uijeongbu, "의정부"),
        ("에버라인", .everline, "에버"),
        ("김포", .gimpo, "김포"),
        ("1호선", .line1, "1"),
        ("2호선", .line2, "2"),
        ("3호선", .line3, "3"),
        ("4호선", .line4, "4"),
        ("5호선", .line5, "5"),
        ("6호선", .line6, "6"),
        ("7호선", .line7, "7"),
        ("8호선", .line8, "8"),
        ("9호선", .line9, "9"),
    ]

    private static func subwayKind(routeName: String?) -> DSTransportBadge.Kind {
        guard let routeName else { return .subway(.line1, text: "지하철") }
        for entry in subwayLineTable where routeName.contains(entry.keyword) {
            return .subway(entry.line, text: entry.badge)
        }
        // TODO: 실서버 노선명 실측 후 테이블 확장 — 미매핑 노선은 원문 텍스트 유지, 색상은 best-effort.
        return .subway(.line1, text: routeName)
    }
}
