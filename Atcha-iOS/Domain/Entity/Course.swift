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
}

extension Course {
    
}

struct LegTrafficInfo {
    let departureDateTime: String?
    let totalTime: String?
    
    // Legs밑에 있는 애들
    let sectionTime: String?
    let mode: TransportMode?
    let type: String?
    let passStopList: [passStopList]?
    let route: String? // "간선:N62"
    
    let steps: [Step]? // 보행자 이동 거리 (미터)
}

extension Course {
    func toLegTrafficInfos() -> [LegTrafficInfo] {
        return legs.map { leg in
            LegTrafficInfo(departureDateTime: departureDateTime,
                           totalTime: "\(totalTime)",
                           sectionTime: "\(leg.sectionTime)",
                           mode: leg.mode,
                           type: leg.type,
                           passStopList: leg.passStopList,
                           route: leg.route,
                           steps: leg.step)
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
