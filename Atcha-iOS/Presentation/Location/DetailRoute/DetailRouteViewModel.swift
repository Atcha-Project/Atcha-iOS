//
//  DetailRouteViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import Foundation
import UIKit
import CoreLocation

final class DetailRouteViewModel: BaseViewModel {
    private let busInfoUseCase: BusInfoUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private var streamTask: Task<Void, Never>?
    
    private let infos: LegInfo
    
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var address: String
    @Published var legtPathInfo: [LegPathInfo] = []
    @Published var legTrafficInfo: [LegTrafficInfo] = []
    @Published var busRealTimeInfos: [BusRealTimeInfo] = []
    
    init(address: String,
         infos: LegInfo,
         busInfoUseCase: BusInfoUseCase,
         authorizationUseCase: RequestLocationAuthorizationUseCase,
         streamUseCase: ObserveLocationStreamUseCase) {
        self.infos = infos
        self.address = address
        
        self.busInfoUseCase = busInfoUseCase
        self.authorizationUseCase = authorizationUseCase
        self.streamUseCase = streamUseCase
        
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
    
    func requestPermissionAndStartTracking() {
        Task {
            let status = await authorizationUseCase.askLocationPermission()
            guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
            
            streamTask = Task {
                for await location in streamUseCase.startUpdate() {
                    let currentLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                                 longitude: location.coordinate.longitude)
                    
                    self.currentLocation = currentLocation
                    break
                }
            }
        }
    }
    
    func setupLocation() {
        requestPermissionAndStartTracking()
    }
}
