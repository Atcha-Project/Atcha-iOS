//
//  DetailRouteInfoLayoutType.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 9/14/25.
//

import Foundation

enum DetailRouteInfoLayoutType: Hashable {
//    case summary
    case start
    case transport(TransportMode)
    case end
}

struct LegTrafficUIInfo: Hashable {
    let type: DetailRouteInfoLayoutType
    let info: LegTrafficInfo
}
