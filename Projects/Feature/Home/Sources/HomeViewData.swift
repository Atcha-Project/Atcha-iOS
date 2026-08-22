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

/// 홈에 표출되는 선택 경로 카드. Entity를 뷰에 직접 노출하지 않는다.
struct RouteCardViewData: Equatable {
    let badgeText: String?
    let departureTimeText: String
    let legs: [DSTransportBadge.Kind]
    let summaryText: String?
    let destinationText: String

    init(entity: LastRoute) {
        badgeText = "가장 늦은 차"
        departureTimeText = "\(timeFormatter.string(from: entity.departureTime)) 출발"
        legs = TransportBadgeMapper.kinds(for: entity.legs)
        summaryText = Self.summary(from: entity.legs)

        let arrival = entity.departureTime.addingTimeInterval(TimeInterval(entity.totalTime))
        destinationText = "도착 \(timeFormatter.string(from: arrival)) · 환승 \(entity.transferCount)회"
    }

    var dsContent: DSRouteCard.Content {
        .init(
            badgeText: badgeText,
            departureTimeText: departureTimeText,
            legs: legs,
            summaryText: summaryText,
            destinationText: destinationText
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
