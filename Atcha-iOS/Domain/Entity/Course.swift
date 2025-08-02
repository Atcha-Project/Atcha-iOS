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
            passStations:leg.passStopList?.map {
                PassStations(
                    index: $0.index,
                    stationName: $0.stationName,
                    lat: $0.lat,
                    lon: $0.lon
                )
            }
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
    let start: addressInfo?
    let end: addressInfo?
    let passStopList: [PassStopList]?
    let step: [Step]?
    let passShape: String? // 경로그리기
    
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

struct LegInfo {
    let pathInfo: [LegPathInfo]
    let trafficInfo: [LegTrafficInfo]
}

struct LegTrafficInfo: Hashable {
    let id: UUID = UUID()
    let distance: Int?
    let departureDateTime: String?
    let totalTime: String?
    let sectionTime: String?
    let mode: TransportMode?
    let type: String?
    let passStopList: [PassStopList]?
    let steps: [Step]? // 보행자 이동 거리 (미터)
    let busName: String?
    var timeText: String?
}

extension Course {
    func toLegTrafficInfos() -> [LegTrafficInfo] {
        let timeText = makeStartEndTime(departure: departureDateTime,
                                        totalTime: formattedTotalTime)
        
        return legs.map { leg in
            LegTrafficInfo(distance: leg.distance,
                           departureDateTime: departureDateTime,
                           totalTime: formattedTotalTime,
                           sectionTime: leg.formattedSectionTimeRounded,
                           mode: leg.mode,
                           type: leg.type,
                           passStopList: leg.passStopList,
                           steps: leg.step,
                           busName: leg.busName,
                           timeText: timeText)
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

struct addressInfo: Codable, Hashable{
    let name: String?
    let lon: Double?
    let lat: Double?
}

struct PassStopList: Codable, Hashable {
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

enum TransportMode: String, Codable {
    case walk = "WALK"
    case bus = "BUS"
    case subway = "SUBWAY"
    case unknown
    
    var icon: UIImage? {
        switch self {
            //        case .bus: return UIImage.routeCircleLineBus
            //        case .subway: return UIImage.routeCircleLineSubway
            //        default: return UIImage.routeCircleLineWalk
        case .bus: return UIImage.routeBusWhite
        case .subway: return UIImage.routeCircleSubway
        default: return UIImage.routeCircleWalk
        }
    }
    
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
            return .gray800
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

struct LegPathInfo {
    let routeId: String?
    let departureDateTime: String?
    let mode: TransportMode?
    let type: String?
    let step: [Step]?
    let passShape: String?
}

struct BusDetailInfo {
    let routeName: String?
    let start: addressInfo?
    let passStations: [PassStations]?
}
