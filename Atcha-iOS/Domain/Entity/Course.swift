//
//  Course.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/17/25.
//

import UIKit

struct Course: Codable, Hashable {
    let routeId: String?
    let departureDateTime: String?
    let totalTime: Int?
    let totalWalkTime: Int?
    let transferCount: Int?
    let totalDistance: Int?
    let totalWalkDistance: Int?
    let pathType: Int?
    let legs: [Legs]
    
    var formattedTotalTime: String {
        guard let totalTime = totalTime else { return "N/A" }
        
        let totalMinutes = Int(round(Double(totalTime) / 60.0))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours)시간 \(minutes)분" : "\(hours)시간"
        } else {
            return "\(minutes)분"
        }
    }
    
    func toBusDetailInfo(for route: String) -> BusDetailInfo? {
        guard let leg = legs.first(where: { $0.mode == .bus && $0.route == route }) else {
            return nil
        }
        
        return BusDetailInfo(
            routeName: leg.route,
            start: leg.start,
            passStations: leg.passStopList?.map {
                PassStations(
                    index: $0.index,
                    stationName: $0.stationName,
                    lat: $0.lat,
                    lon: $0.lon
                )
            },
            targetBusStation: leg.targetBusStation
        )
    }
    
    private func makeStartEndTime(departure: String?, totalTime: String?) -> String? {
        guard
            let departure = departure,
            let totalTime = totalTime
        else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "ko_KR")
        
        guard let departureDate = formatter.date(from: departure) else { return nil }
        
        let minutes = parseTotalTimeToMinutes(totalTime)
        let arrivalDate = departureDate.addingTimeInterval(TimeInterval(minutes * 60))
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "HH:mm"
        
        return "\(displayFormatter.string(from: departureDate)) ~ \(displayFormatter.string(from: arrivalDate))"
    }
    
    private func parseTotalTimeToMinutes(_ time: String) -> Int {
        var totalMinutes = 0
        
        if let hourMatch = time.range(of: "\\d+(?=시간)", options: .regularExpression),
           let hour = Int(time[hourMatch]) {
            totalMinutes += hour * 60
        }
        
        if let minuteMatch = time.range(of: "\\d+(?=분)", options: .regularExpression),
           let minute = Int(time[minuteMatch]) {
            totalMinutes += minute
        }
        
        return totalMinutes
    }
}

struct Legs: Codable, Hashable {
    let distance: Int? // 거리체크
    let sectionTime: Int?
    let mode: TransportMode?
    let departureDateTime: String?
    let route: String?
    let type: String?
    let service: String?
    let start: AddressInfo?
    let end: AddressInfo?
    let passStopList: [PassStopList]?
    let step: [Step]?
    let passShape: String? // 경로그리기
    let subwayFinalStation: String?
    let subwayDirection: String?
    let targetBusStation: [TargetBusStation]?
    let targetBusTerm: Int?
    
    var formattedSectionTimeRounded: String {
        guard let totalTime = sectionTime else { return "N/A" }
        let minutes = totalTime / 60 + ((totalTime % 60) >= 30 ? 1 : 0)
        return "\(minutes)분"
    }
    
    var busName: String {
        guard let route = route, let mode = mode else { return "N/A" }
        
        if mode == .bus {
            if let colonIndex = route.firstIndex(of: ":") {
                let substring = route[route.index(after: colonIndex)...]
                return String(substring)
            }
        }
        
        return route
    }
}

struct LegInfo: Codable, Equatable {
    let pathInfo: [LegPathInfo]
    let trafficInfo: [LegTrafficInfo]
    let busInfo: [BusDetailInfo]
}

struct LegTrafficInfo: Hashable, Codable, Equatable {
    var id: UUID = UUID()
    let distance: Int?
    let departureDateTime: String?
    let arrivalDateTime: String?
    let totalTime: String?
    let sectionTime: String?
    let mode: TransportMode?
    let type: String?
    let passStopList: [PassStopList]?
    let steps: [Step]? // 보행자 이동 거리 (미터)
    let busName: String?
    var subwayStartTime: String?
    let route: String?
    var timeText: String?
    let targetBusStation: [TargetBusStation]?
    let targetBusTerm: Int?
    let startTime: String?
    let endTime: String?
}

extension Course {
    func toLegTrafficInfos() -> [LegTrafficInfo] {
        let timeText = makeStartEndTime(departure: departureDateTime,
                                        totalTime: formattedTotalTime)
        
        return legs.map { leg in
            LegTrafficInfo(distance: leg.distance,
                           departureDateTime: formatToHourMinute(departureDateTime),
                           arrivalDateTime: addSecondsToTime(from: departureDateTime, plusSeconds: totalTime ?? 0),
                           totalTime: formattedTotalTime,
                           sectionTime: leg.formattedSectionTimeRounded,
                           mode: leg.mode,
                           type: leg.type,
                           passStopList: leg.passStopList,
                           steps: leg.step,
                           busName: leg.busName,
                           subwayStartTime: leg.departureDateTime,
                           route: leg.route,
                           timeText: timeText,
                           targetBusStation: leg.targetBusStation,
                           targetBusTerm: leg.targetBusTerm,
                           startTime: formatToHourMinute(leg.departureDateTime) ?? "",
                           endTime: addSecondsToTime(from: leg.departureDateTime ?? "", plusSeconds: leg.sectionTime ?? 0)
            )
        }
    }
    
    func formatToHourMinute(_ isoDate: String?) -> String? {
        guard let isoDate = isoDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        guard let date = formatter.date(from: isoDate) else { return nil }
        
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func addSecondsToTime(from isoDate: String?, plusSeconds: Int) -> String? {
        guard let isoDate = isoDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        guard let date = formatter.date(from: isoDate) else { return nil }
        
        let updatedDate = date.addingTimeInterval(TimeInterval(plusSeconds))
        
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: updatedDate)
    }
    
    func toBusInfos() -> [BusDetailInfo] {
        return legs.map { leg in
            return BusDetailInfo(
                routeName: leg.route,
                start: leg.start,
                passStations: leg.passStopList?.map {
                    PassStations(
                        index: $0.index,
                        stationName: $0.stationName,
                        lat: $0.lat,
                        lon: $0.lon
                    )
                },
                targetBusStation: leg.targetBusStation
            )
        }
    }
}

extension Course {
    func toLegPathInfos() -> [LegPathInfo] {
        return legs.map { leg in
            LegPathInfo(
                routeId: self.routeId,
                departureDateTime: self.departureDateTime, // ✅ Course의 값을 사용
                mode: leg.mode,
                type: leg.type,
                step: leg.step,
                passShape: leg.passShape
            )
        }
    }
}

struct AddressInfo: Codable, Equatable, Hashable {
    let name: String?
    let lon: Double?
    let lat: Double?
}

extension AddressInfo {
    init(name: String?, lat: Double?, lon: Double?) {
        self.name = name
        self.lat = lat
        self.lon = lon
    }
}

struct PassStopList: Codable, Hashable, Equatable {
    let index: Int?
    let stationName: String?
    let lon: String?
    let lat: String?
}

struct Step: Codable, Hashable{
    let streetName: String?
    let distance: Double?
    let description: String?
    let linestring: String?
}

struct TargetBusStation: Codable, Hashable, Equatable {
    let busStationId: String?
    let busStationNumber: String?
    let busStationName: String?
}

enum TransportMode: String, Codable, Equatable {
    case walk = "WALK"
    case bus = "BUS"
    case subway = "SUBWAY"
    case unknown
    
    func getIcon(for routeType: String) -> UIImage? {
        switch self {
        case .bus:
            return TransportMode.busIcon[routeType]
        case .subway:
            return TransportMode.subwayIcon[routeType]
        default:
            return nil
        }
    }
    
    func getBorderIcon(for routeType: String) -> UIImage? {
        switch self {
        case .bus:
            return TransportMode.busBorderIcon[routeType]
        case .subway:
            return TransportMode.subwayBorderIcon[routeType]
        default:
            return nil
        }
    }
    
    func getColor(for routeType: String) -> UIColor? {
        switch self {
        case .bus:
            return TransportMode.busColor[routeType]
        case .subway:
            return TransportMode.subwayColor[routeType]
        case .walk:
            return .gray200
        default:
            return nil
        }
    }
    
    func getGageColor(for routeType: String) -> UIColor? {
        switch self {
        case .bus:
            return TransportMode.busColor[routeType]
        case .subway:
            return TransportMode.subwayColor[routeType]
        case .walk:
            return .gray930
        default:
            return nil
        }
    }
    
    func getOffIcon(for routeType: String) -> String? {
        switch self {
        case .bus:
            return TransportMode.busGetOffIcon[routeType]
        case .subway:
            return TransportMode.subwayGetOffIcon[routeType]
        default:
            return nil
        }
    }
}

struct LegPathInfo: Codable, Equatable {
    let routeId: String?
    let departureDateTime: String?
    let mode: TransportMode?
    let type: String?
    let step: [Step]?
    let passShape: String?
}

struct BusDetailInfo: Codable, Equatable {
    let routeName: String?
    let start: AddressInfo?
    let passStations: [PassStations]?
    let targetBusStation: [TargetBusStation]?
}
