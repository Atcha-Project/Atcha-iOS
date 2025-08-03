//
//  DetailRouteViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import Foundation
import UIKit

final class DetailRouteViewModel: BaseViewModel {
    private let busInfoUseCase: BusInfoUseCase
    private let infos: LegInfo
    
    @Published var address: String
    @Published var legtPathInfo: [LegPathInfo] = []
    @Published var legTrafficInfo: [LegTrafficInfo] = []
    @Published var busRealTimeInfos: [BusRealTimeInfo] = []
    
    init(address: String,
         infos: LegInfo,
         busInfoUseCase: BusInfoUseCase) {
        self.infos = infos
        self.address = address
        self.busInfoUseCase = busInfoUseCase
        
        super.init()
        self.fetchInfo()
    }
    
    func fetchInfo() {
        self.legtPathInfo = infos.pathInfo
        self.legTrafficInfo = infos.trafficInfo
        
        let busDetailInfo = infos.busInfo.filter { $0.routeName?.isEmpty == false }
        busDetailInfo.forEach { info in
            let request = BusRealTimeInfoRequest(
                routeName: info.routeName,
                stationName: info.start?.name,
                lat: info.start?.lat,
                lon: info.start?.lon,
                passStations: info.passStations)
            
            Task {
                await busRealTimeInfo(request: request)
            }
        }
    }
    
    @MainActor
    func busRealTimeInfo(request: BusRealTimeInfoRequest) {
        Task {
            do {
                let response = try await busInfoUseCase.busRealTimeInfo(request)
                busRealTimeInfos.append(response)
            } catch {
                print("실시간 버스 조회 실패")
            }
        }
    }
}
