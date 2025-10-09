//
//  DetailRouteViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import Foundation
import UIKit
import CoreLocation

enum DetailRouteContext {
    case beforeRegister
    case afterReigster
}

final class DetailRouteViewModel: BaseViewModel {
    private let busInfoUseCase: BusInfoUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private var streamTask: Task<Void, Never>?
    
    let infos: LegInfo
    var onBusDetail: ((BusDetailInfo) -> Void)?
    var getAlarmTapped: ((String, LegInfo) -> Void)?
    
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var address: String
    @Published var legtPathInfo: [LegPathInfo] = []
    @Published var legTrafficInfo: [LegTrafficInfo] = []
    //    @Published var busRealTimeInfos: [BusRealTimeInfo] = []
    
//    @Published var busRealTimeInfo: [RealTimeBusArrival] = []
    @Published var busRealTimeInfos: [[RealTimeBusArrival]] = []
    
    @Published private(set) var context: DetailRouteContext
    
    init(address: String,
         infos: LegInfo,
         context: DetailRouteContext,
         busInfoUseCase: BusInfoUseCase,
         authorizationUseCase: RequestLocationAuthorizationUseCase,
         streamUseCase: ObserveLocationStreamUseCase) {
        self.infos = infos
        self.address = address
        self.context = context
        self.busInfoUseCase = busInfoUseCase
        self.authorizationUseCase = authorizationUseCase
        self.streamUseCase = streamUseCase
        
        super.init()
        self.fetchInfo()
        self.requestPermissionAndStartTracking()
    }
    
    func fetchInfo() {
        self.legtPathInfo = infos.pathInfo
        self.legTrafficInfo = infos.trafficInfo
        let busDetailInfo = infos.busInfo.filter { $0.routeName?.isEmpty == false }
        
        busDetailInfo.forEach { info in
            Task {
                await getBusRealTimeInfo(request: info.routeName ?? "")
            }
        }
    }
    
    @MainActor
    func getBusRealTimeInfo(request: String) {
        Task {
            do {
                let response = try await busInfoUseCase.getBusRealTimeInfo(request)
                busRealTimeInfos.append(response)
//                busRealTimeInfo = response
                print("실시간 버스 조회 성공요! : \(busRealTimeInfos)")
            } catch {
                print("실시간 버스 조회 실패요!")
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
