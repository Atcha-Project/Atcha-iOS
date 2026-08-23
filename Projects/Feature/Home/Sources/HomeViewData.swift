import DesignSystem
import Domain
import Foundation

// DateFormatter is expensive to create, so cache one at file scope.
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter
}()

/// 신선도 스탬프 문구(Phase 16) — 배너 보조 라인·카드 푸터 공용. 등록 세션이 있고
/// 확인 시각이 있을 때만 문구가 있다. 시각 포맷은 카드와 같은 캐시 포매터를 쓴다.
extension HomeViewModel {
    static func freshnessText(checkedAt: Date?, isRegistered: Bool) -> String? {
        guard isRegistered, let checkedAt else { return nil }
        return "\(timeFormatter.string(from: checkedAt)) 확인 기준"
    }
}

/// 홈에 표출되는 선택 경로 카드. Entity를 뷰에 직접 노출하지 않는다.
struct RouteCardViewData: Equatable {
    /// 카드 톤 — past는 유예 경과 후의 "지난 막차" 상태(비활성 시각, Phase 13).
    enum Tone: Equatable {
        case normal
        case past
    }

    let badgeText: String?
    let departureTimeText: String
    let legs: [DSTransportBadge.Kind]
    let summaryText: String?
    let destinationText: String
    let tone: Tone

    init(entity: LastRoute) {
        badgeText = "가장 늦은 차"
        departureTimeText = "\(timeFormatter.string(from: entity.departureTime)) 출발"
        legs = TransportBadgeMapper.kinds(for: entity.legs)
        summaryText = Self.summary(from: entity.legs)

        let arrival = entity.departureTime.addingTimeInterval(TimeInterval(entity.totalTime))
        destinationText = "도착 \(timeFormatter.string(from: arrival)) · 환승 \(entity.transferCount)회"
        tone = .normal
    }

    private init(
        badgeText: String?,
        departureTimeText: String,
        legs: [DSTransportBadge.Kind],
        summaryText: String?,
        destinationText: String,
        tone: Tone
    ) {
        self.badgeText = badgeText
        self.departureTimeText = departureTimeText
        self.legs = legs
        self.summaryText = summaryText
        self.destinationText = destinationText
        self.tone = tone
    }

    /// 유예 경과 후의 "지난 막차" 카드 — 비활성 톤 + "HH:mm 출발이었어요" (Phase 13).
    /// 시각은 카드의 등록 시점 문자열이 아니라 최신 세션 출발 시각(서버 갱신 반영)을 받는다.
    func asPastTrain(departure: Date) -> RouteCardViewData {
        RouteCardViewData(
            badgeText: "지난 막차",
            departureTimeText: "\(timeFormatter.string(from: departure)) 출발이었어요",
            legs: legs,
            summaryText: summaryText,
            destinationText: destinationText,
            tone: .past
        )
    }

    /// footnote(신선도 스탬프)는 카드 사실이 아니라 세션 상태라 State가 따로 나른다 —
    /// VC가 표출 시점에 합성한다(Phase 16).
    func dsContent(footnote: String?) -> DSRouteCard.Content {
        .init(
            badgeText: badgeText,
            departureTimeText: departureTimeText,
            legs: legs,
            summaryText: summaryText,
            destinationText: destinationText,
            footnoteText: footnote,
            tone: tone == .past ? .muted : .normal
        )
    }

    // "탑승지 → 환승지 → 하차지" — 도보 구간은 경유지로 세지 않는다.
    private static func summary(from legs: [TransportLeg]) -> String? {
        let rideLegs = legs.filter { $0.mode != .walk }
        var names = rideLegs.compactMap { $0.start?.name }
        if let lastEnd = rideLegs.last?.end?.name {
            names.append(lastEnd)
        }
        return names.isEmpty ? nil : names.joined(separator: " → ")
    }
}
