@testable import DesignSystem
import Testing

/// 이 테이블은 Home·Search에 복제돼 있던 동안 테스트가 하나도 없었다.
/// DesignSystem으로 모으면서 규칙을 고정한다.
struct DSTransportBadgeRouteNameTests {
    // MARK: - 버스

    @Test(arguments: [
        ("간선:472", DSBusType.mainline, "472"),
        ("지선:6642", DSBusType.regular, "6642"),
        ("마을:서초08", DSBusType.town, "서초08"),
        ("광역:9401", DSBusType.widearea, "9401"),
        ("직행:1005", DSBusType.widearea, "1005"),
    ])
    func bus_legacyFormat_mapsTypeAndNumber(routeName: String, type: DSBusType, text: String) {
        #expect(DSTransportBadge.Kind.bus(legacyRouteName: routeName) == .bus(type, text: text))
    }

    /// 모르는 종류는 색만 기본값으로 떨어뜨리고 번호는 지킨다.
    @Test
    func bus_unknownType_keepsNumberWithGeneralColor() {
        #expect(DSTransportBadge.Kind.bus(legacyRouteName: "심야:N26") == .bus(.general, text: "N26"))
    }

    /// 콜론이 없으면 원문 전체가 배지 텍스트다 — 이름을 잃는 것보다 낫다.
    @Test
    func bus_withoutColon_usesRawNameAsText() {
        #expect(DSTransportBadge.Kind.bus(legacyRouteName: "472") == .bus(.general, text: "472"))
    }

    @Test
    func bus_nilRouteName_fallsBackToLabel() {
        #expect(DSTransportBadge.Kind.bus(legacyRouteName: nil) == .bus(.general, text: "버스"))
    }

    // MARK: - 지하철

    @Test(arguments: [
        ("1호선", DSSubwayLine.line1, "1"),
        ("9호선", DSSubwayLine.line9, "9"),
        ("수인분당선", DSSubwayLine.suinBundang, "수인분당"),
        ("신분당선", DSSubwayLine.shinbundang, "신분당"),
        ("경의중앙선", DSSubwayLine.gyeonguiJungang, "경의중앙"),
        ("공항철도", DSSubwayLine.airport, "공항"),
        ("GTX-A", DSSubwayLine.gtxA, "GTX-A"),
        ("우이신설선", DSSubwayLine.uiSinseol, "우이신설"),
    ])
    func subway_knownLine_mapsToPaletteAndBadgeText(
        routeName: String, line: DSSubwayLine, text: String
    ) {
        #expect(DSTransportBadge.Kind.subway(routeName: routeName) == .subway(line, text: text))
    }

    /// **테이블 순서가 규칙이다.** 구별되는 이름이 "N호선"보다 먼저 와야 한다 —
    /// 이 테스트가 깨지면 테이블에 줄을 잘못된 위치에 넣은 것이다.
    @Test(arguments: [
        ("인천 1호선", DSSubwayLine.incheon1, "인천1"),
        ("인천1호선", DSSubwayLine.incheon1, "인천1"),
        ("인천 2호선", DSSubwayLine.incheon2, "인천2"),
        ("의정부경전철", DSSubwayLine.uijeongbu, "의정부"),
        ("김포골드라인", DSSubwayLine.gimpo, "김포"),
    ])
    func subway_distinctiveNames_winOverBareLineNumbers(
        routeName: String, line: DSSubwayLine, text: String
    ) {
        #expect(DSTransportBadge.Kind.subway(routeName: routeName) == .subway(line, text: text))
    }

    /// 미매핑 노선은 원문을 유지한다 — 색이 틀리는 편이 이름이 사라지는 것보다 낫다.
    @Test
    func subway_unmappedLine_keepsRawNameWithBestEffortColor() {
        #expect(DSTransportBadge.Kind.subway(routeName: "동해선") == .subway(.line1, text: "동해선"))
    }

    @Test
    func subway_nilRouteName_fallsBackToLabel() {
        #expect(DSTransportBadge.Kind.subway(routeName: nil) == .subway(.line1, text: "지하철"))
    }
}
