//
//  DetailRouteViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import Foundation
import UIKit

final class DetailRouteViewModel: BaseViewModel {
    private let infos: LegInfo
    @Published var legtPathInfo: [LegPathInfo] = []
    @Published var legTrafficInfo: [LegTrafficInfo] = []
    
    init(infos: LegInfo) {
        self.infos = infos
        
        super.init()
        self.bind()
    }
    
    private func bind() {
        self.legtPathInfo = infos.pathInfo
        self.legTrafficInfo = infos.trafficInfo
        
        // 시간
//        let time = legTrafficInfo.first?.departureDateTime //  Optional("2025-08-01T00:31:19")
//        let totalTime = legTrafficInfo.first?.totalTime // Optional("5분 15초")
        
        let infos = legTrafficInfo.forEach { info in
            switch info.mode {
            case .bus:
                print("busStart : =================================")
                let stations = info.passStopList?.compactMap { $0.stationName }
                print("\(info.sectionTime)분, \(stations?.count)개 정류장 이동")
                print("busName: \(info.busName)")
                print("\(stations?.first) 승차")
                print("\(stations?.last) 하차")
            case .subway:
                print("subwayStart : =================================")
                let stations = info.passStopList?.compactMap { $0.stationName }
                print("passStopList : \(info.passStopList)")
                
                print("\(info.sectionTime)분, \(stations?.count)개 정류장 이동")
                print("\(stations?.first) 승차")
                print("\(stations?.last) 하차")
            case .walk:
                print("walkStart : =================================")
                print("\(info.sectionTime)분 걷기")
                let totalDistance = info.steps?.compactMap { $0.distance }.reduce(0, +) ?? 0
                print("총 거리: \(totalDistance)m")
            default: do {}
            }
//            sectionTime : Optional("6분")
//            sectionTime : Optional("3분")
//            sectionTime : Optional("2분")
        }
    }
}
