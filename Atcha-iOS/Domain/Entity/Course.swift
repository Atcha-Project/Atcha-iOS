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
        
        let minutes = totalTime / 60
        let seconds = totalTime % 60
        
        return String(format: "%d분 %02d초", minutes, seconds)
    }
}

struct Legs: Codable, Hashable {
    let distance: Int?
    let sectionTime: Int?
    let mode: TransportMode?
    let departureDateTime: String?
    let route: String?
    let type: String?
    let service: String?
    let start: addressInfo?
    let end: addressInfo?
    let passStopList: [passStopList]?
    let step: [Step]?
    let passShape: String?
    
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

struct LegTrafficInfo {
    let departureDateTime: String?
    let totalTime: String?
    let sectionTime: String?
    let mode: TransportMode?
    let type: String?
    let passStopList: [passStopList]?
    let steps: [Step]? // 보행자 이동 거리 (미터)
    let busName: String?
}

extension Course {
    func toLegTrafficInfos() -> [LegTrafficInfo] {
        return legs.map { leg in
            LegTrafficInfo(departureDateTime: departureDateTime,
                           totalTime: formattedTotalTime,
                           sectionTime: leg.formattedSectionTimeRounded,
                           mode: leg.mode,
                           type: leg.type,
                           passStopList: leg.passStopList,
                           steps: leg.step,
                           busName: leg.busName)
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
    let lan: Double?
}

struct passStopList: Codable, Hashable {
    let index: Int?
    let stationName: String?
    let lon: String?
    let lan: String?
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
