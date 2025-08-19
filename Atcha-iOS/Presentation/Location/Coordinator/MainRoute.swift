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
    case changeCourse(location: Location)
    case detailRoute(address: String, infos: LegInfo, context: DetailRouteContext)
    case lockScreen(info: LegInfo?, address: String?) // 잠금화면
    case proximity // 가까운 거리 알림 모달
}
