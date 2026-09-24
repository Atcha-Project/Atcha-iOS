import Foundation

/// 서버 노선명 문자열 → 배지 종류. **문자열 파싱만** 여기 산다.
///
/// 이 파일이 DesignSystem에 있는 이유와, 그럼에도 Domain을 import하지 않는 이유가
/// 같은 하나다. 노선 테이블은 **팔레트와 짝**이라 색이 추가되면 여기도 같이 바뀐다 —
/// 그래서 DesignSystem에 있어야 한다. 반대로 `DSTransportBadge.Kind`는 의도적으로
/// Domain 타입이 아니므로(같은 파일 상단 주석), DesignSystem이 `TransportLeg`을 알게
/// 되면 디자인 시스템이 비즈니스 엔티티에 묶인다. 경계를 문자열에 두면 둘 다 지킨다.
///
/// 피처는 `leg.mode` switch(약 10줄)만 들고 이 팩토리를 부른다. 이전에는 이 테이블
/// 전체가 Home·Search에 **바이트 단위로 복제**돼 있었고, 노선 하나를 추가하면 두 곳을
/// 같이 고쳐야 했다.
public extension DSTransportBadge.Kind {
    /// 레거시 서버 형식: `"간선:472"` (종류:번호). 형식이 아니면 원문을 그대로 쓴다.
    static func bus(legacyRouteName routeName: String?) -> DSTransportBadge.Kind {
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

    /// 미매핑 노선은 원문 텍스트를 유지하고 색만 best-effort로 준다 — 이름이 사라지는
    /// 것보다 색이 틀리는 편이 낫다.
    static func subway(routeName: String?) -> DSTransportBadge.Kind {
        guard let routeName else { return .subway(.line1, text: "지하철") }
        for entry in subwayLineTable where routeName.contains(entry.keyword) {
            return .subway(entry.line, text: entry.badge)
        }
        // TODO: 실서버 노선명 실측 후 테이블 확장.
        return .subway(.line1, text: routeName)
    }

    /// **순서가 규칙이다.** 구별되는 이름이 맨숭맨숭한 "N호선"보다 먼저 와야 한다 —
    /// "인천 1호선"이 "1호선"으로 떨어지면 안 된다. 테이블에 줄을 추가할 때는 위치가
    /// 곧 우선순위다.
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
}
