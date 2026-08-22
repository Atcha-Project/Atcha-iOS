import DesignSystem
import Domain
import Foundation

// Every route in the flow formats with the same pattern; DateFormatter is
// expensive to create, so cache one at file scope.
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter
}()

struct PlaceViewData: Equatable {
    let name: String
    let address: String

    init(entity: Place) {
        name = entity.name
        address = entity.address
    }
}

struct RouteViewData: Equatable {
    let badgeText: String?
    let departureTimeText: String
    let legs: [DSTransportBadge.Kind]
    let summaryText: String?
    let destinationText: String

    init(entity: LastRoute, isFeatured: Bool) {
        badgeText = isFeatured ? "가장 늦은 차" : nil
        departureTimeText = "\(timeFormatter.string(from: entity.departureTime)) 출발"
        legs = TransportBadgeMapper.kinds(for: entity.legs)
        summaryText = Self.summary(from: entity.legs)

        let arrival = entity.departureTime.addingTimeInterval(TimeInterval(entity.totalTime))
        destinationText = "도착 \(timeFormatter.string(from: arrival)) · 환승 \(entity.transferCount)회"
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

struct RouteResultsViewData: Equatable {
    let featured: RouteViewData
    let alternatives: [RouteViewData]
    let isExpanded: Bool

    /// `entities`는 비어 있지 않아야 한다 (`.available`이 상류에서 보장).
    init(entities: [LastRoute], isExpanded: Bool) {
        featured = RouteViewData(entity: entities[0], isFeatured: true)
        alternatives = entities.dropFirst().map { RouteViewData(entity: $0, isFeatured: false) }
        self.isExpanded = isExpanded
    }
}
