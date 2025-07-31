//
//  BusDetailViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/29/25.
//

import Foundation
import UIKit

struct BusRouteInfo {
    let busRouteId: String?
    let routeName: String?
    let serviceRegion: String?
}

final class BusDetailViewModel: BaseViewModel {
    let busType: BusType
    let busNumber: String
    let busDetailInfo: BusDetailInfo
    private let busInfoUseCase: BusInfoUseCase
    var busRouteInfo = BusRouteInfo(busRouteId: "", routeName: "", serviceRegion: "")
    var onInfoTap: (() -> Void)?
    
    @Published var busPositionInfo: BusPositionInfo?
    
    init(
        busInfoUseCase: BusInfoUseCase,
        busDetailInfo: BusDetailInfo
    ) {
        self.busInfoUseCase = busInfoUseCase
        
        guard let routeName = busDetailInfo.routeName else {
            fatalError("routeName is nil")
        }
        let split = routeName.splitRouteName()
        self.busType = BusType(from: split.type)
        self.busNumber = split.number
        self.busDetailInfo = busDetailInfo
        super.init()
        
        let request = BusRealTimeInfoRequest(
            routeName: busDetailInfo.routeName,
            stationName: busDetailInfo.start?.name,
            lat: busDetailInfo.start?.lat,
            lon: busDetailInfo.start?.lon,
            passStations: busDetailInfo.passStations)
        
        Task { [weak self] in
            await self?.busRealTimeInfo(request: request)
        }
    }
    
    var icon: UIImage {
        return busType.icon
    }
    
    // MARK: - 실시간 버스 정보 조회
    @MainActor
    func busRealTimeInfo(request: BusRealTimeInfoRequest) {
        Task {
            do {
                let response = try await busInfoUseCase.busRealTimeInfo(request)
                self.busRouteInfo = response.toBusRouteInfo()
                
                let positionRequest = BusPositionInfoRequest(
                    busRouteId: busRouteInfo.busRouteId,
                    routeName: busRouteInfo.routeName,
                    serviceRegion: busRouteInfo.serviceRegion
                )
                self.busPositionInfo(request: positionRequest)
                
            } catch {
                print("실시간 버스 조회 실패")
            }
        }
    }
    
    // MARK: - 버스 위치 정보 조회
    @MainActor
    func busPositionInfo(request: BusPositionInfoRequest) {
        Task {
            do {
                let response = try await busInfoUseCase.busPositionInfo(request)
                self.busPositionInfo = response
                print("실시간 버스 조회: \(response)")
            } catch {
                print("실시간 버스 조회 실패")
            }
        }
    }
}
