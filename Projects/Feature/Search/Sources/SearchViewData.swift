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

/// 자정 넘김 표기(Phase 17) — 내일이면 "내일 " 접두, 오늘·그 외는 무라벨(무라벨 = 오늘).
/// 이틀+ 미래·과거는 막차 도메인상 비발생 — 방어적 무라벨. 피처 간 공유 모듈을 만들지
/// 않으므로 HomeFeature와 중복이다(TransportBadgeMapper 선례).
func dayPrefix(for date: Date, now: Date, calendar: Calendar = .current) -> String {
    guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return "" }
    return calendar.isDate(date, inSameDayAs: tomorrow) ? "내일 " : ""
}

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

    init(entity: LastRoute, isFeatured: Bool, now: Date) {
        badgeText = isFeatured ? "가장 늦은 차" : nil
        let departurePrefix = dayPrefix(for: entity.departureTime, now: now)
        departureTimeText = "\(departurePrefix)\(timeFormatter.string(from: entity.departureTime)) 출발"
        legs = TransportBadgeMapper.kinds(for: entity.legs)
        summaryText = Self.summary(from: entity.legs)

        let arrival = entity.departureTime.addingTimeInterval(TimeInterval(entity.totalTime))
        let arrivalPrefix = dayPrefix(for: arrival, now: now)
        destinationText = "도착 \(arrivalPrefix)\(timeFormatter.string(from: arrival)) · 환승 \(entity.transferCount)회"
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
    init(entities: [LastRoute], isExpanded: Bool, now: Date) {
        featured = RouteViewData(entity: entities[0], isFeatured: true, now: now)
        alternatives = entities.dropFirst().map {
            RouteViewData(entity: $0, isFeatured: false, now: now)
        }
        self.isExpanded = isExpanded
    }
}
