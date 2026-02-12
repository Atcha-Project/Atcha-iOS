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
    private let subwayInfoUseCase: SubwayInfoUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private let alarmUseCase: AlarmUseCase
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
    private var busRoutes: [String] = []
    private var busRealTimeMap: [String: [RealTimeBusArrival]] = [:]
    private var busPollingTask: Task<Void, Never>?
    
    @Published var subwayRealTimeInfos: [SubwayRealTimeInfo] = []
    
    @Published private(set) var context: DetailRouteContext
    
    deinit {
        stopBusPolling()
    }
    
    init(address: String,
         infos: LegInfo,
         context: DetailRouteContext,
         busInfoUseCase: BusInfoUseCase,
         subwayInfoUseCase: SubwayInfoUseCase,
         authorizationUseCase: RequestLocationAuthorizationUseCase,
         streamUseCase: ObserveLocationStreamUseCase,
         alarmUseCase: AlarmUseCase) {
        self.infos = infos
        self.address = address
        self.context = context
        self.busInfoUseCase = busInfoUseCase
        self.subwayInfoUseCase = subwayInfoUseCase
        self.authorizationUseCase = authorizationUseCase
        self.streamUseCase = streamUseCase
        self.alarmUseCase = alarmUseCase
        
        super.init()
        self.fetchInfo()
        self.requestPermissionAndStartTracking()
    }
    
    func fetchInfo() {
        legtPathInfo = infos.pathInfo
        legTrafficInfo = infos.trafficInfo
        
        guard context == .afterReigster else { return }
        // 버스
        let routes = infos.busInfo
            .compactMap { $0.routeName }
            .filter { !$0.isEmpty && $0.contains(":") }
        
        busRoutes = Array(Set(routes)) // 중복 제거
        busRealTimeMap.removeAll()
        busRealTimeInfos = []
        
        // 최초 1회 로드
        Task { [weak self] in
            await self?.refreshAllBusRealTime()
        }
        
        // 15초 폴링 시작
        startBusPolling()
        
        subwayRealTimeInfos = []
        let subwayRoutes = Array(Set(
            infos.trafficInfo
                .filter { $0.mode == .subway }
                .compactMap { $0.route }
                .filter { !$0.isEmpty }
        ))
        
        subwayRoutes.forEach { route in
            Task { await getSubwayRealTimeInfo(routeName: route) }
        }
    }
    
    @MainActor
    func getBusRealTimeInfo(request: String) {
        Task {
            do {
                let response = try await busInfoUseCase.getBusRealTimeInfo(request)
                busRealTimeInfos.append(response)
                //                busRealTimeInfo = response
            } catch {
                print("실시간 버스 조회 실패요!")
            }
        }
    }
    
    @MainActor
    func getSubwayRealTimeInfo(routeName: String) async {
        do {
            let infos = try await subwayInfoUseCase.subwayRealTimeInfo(.init(routeName: routeName))
            subwayRealTimeInfos.removeAll { $0.routeName == routeName } // 기존 제거
            subwayRealTimeInfos.append(contentsOf: infos)
        } catch {
            print("실시간 지하철 조회 실패: \(error)")
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
    
    func alarmRegister(_ request: AlarmRequest) {
        Task {
            do {
                let _ = try await alarmUseCase.alarmRegister(request)
                
                UserDefaultsWrapper.shared.set(
                    false,
                    forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue
                )
                AlarmManager.shared.ensureBackgroundSilentRunning()
                print("알람 등록")
            } catch {
                print("알람 등록 실패: \(error)")
            }
        }
    }
    
    private func startBusPolling() {
        stopBusPolling()
        
        busPollingTask = Task { [weak self] in
            guard let self else { return }
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                if Task.isCancelled { break }
                await self.refreshAllBusRealTime()
            }
        }
    }
    
    private func stopBusPolling() {
        busPollingTask?.cancel()
        busPollingTask = nil
    }
    
    @MainActor
    private func refreshAllBusRealTime() async {
        guard !busRoutes.isEmpty else { return }
        
        // 병렬로 받아오고 싶으면 TaskGroup, 단순이면 for-await도 OK
        for route in busRoutes {
            do {
                let response = try await busInfoUseCase.getBusRealTimeInfo(route)
                busRealTimeMap[route] = response
            } catch {
                // 실패했을 때 기존 값 유지(중요: 여기서 map 지우면 UI가 "꺼짐")
                print("실시간 버스 조회 실패: \(route), \(error)")
            }
        }
        
        // UI용 배열 갱신 (순서가 중요하면 busRoutes 순서대로)
        busRealTimeInfos = busRoutes.compactMap { busRealTimeMap[$0] }
    }
    
}
