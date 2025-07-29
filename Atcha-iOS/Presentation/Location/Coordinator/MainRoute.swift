//
//  MainRoute.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/6/25.
//

import Foundation

enum MainRoute {
    case myPage
    case courseSearch(startLat: String, startLon: String, startAddress: String)
    case changeCourse
    case detailRoute(routeId: String)
}
