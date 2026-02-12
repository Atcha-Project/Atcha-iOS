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
    private var subwayRoutes: [String] = []
    private var subwayPollingTask: Task<Void, Never>?
    
    @Published private(set) var context: DetailRouteContext
    @Published var nearLegIDs: Set<UUID> = []
    
    @Published var deviceHeading: CLLocationDirection?
    private let headingManager = HeadingManager()
    
//
//#if DEBUG
//@Published var mockLocation: CLLocationCoordinate2D? = nil
//#endif

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
        
        let subwayRoutes = Array(Set(
            infos.trafficInfo
                .filter { $0.mode == .subway }
                .compactMap { $0.route }
                .filter { !$0.isEmpty }
        ))
        
        self.subwayRoutes = subwayRoutes
        // 여기서 removeAll 하면 첫 표시가 비었다가 생길 수 있음.
        // "최초 진입 때만 비우고", 폴링에서는 기존 유지가 더 안정적.
        self.subwayRealTimeInfos = []
        
        Task { [weak self] in
            await self?.refreshAllSubwayRealTime()
        }
        startSubwayPolling()
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

                streamTask?.cancel()
                streamTask = Task {
                    for await location in streamUseCase.startUpdate() {
                        let coord = CLLocationCoordinate2D(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        )
                        await MainActor.run { self.currentLocation = coord }
                    }
                }
            }
        }
    
    func startHeading() {
            headingManager.onHeading = { [weak self] h in
                DispatchQueue.main.async { self?.deviceHeading = h }
            }
            headingManager.start()
        }

        func stopHeading() {
            headingManager.stop()
        }

        func stopTracking() {
            streamTask?.cancel()
            streamUseCase.stopUpdate()
            headingManager.stop()
        }

        deinit {
            stopTracking()
            stopBusPolling()
            stopSubwayPolling()
        }
    
//    func requestPermissionAndStartTracking() {
//        Task {
//            let status = await authorizationUseCase.askLocationPermission()
//            guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
//
//            streamTask = Task { [weak self] in
//                guard let self else { return }
//
//                for await location in streamUseCase.startUpdate() {
//                    let real = CLLocationCoordinate2D(
//                        latitude: location.coordinate.latitude,
//                        longitude: location.coordinate.longitude
//                    )
//
//                    #if DEBUG
//                    // ✅ 디버그에선 mock 있으면 그걸로 덮어씀
//                    if let mock = self.mockLocation {
//                        self.currentLocation = mock
//                    } else {
//                        self.currentLocation = real
//                    }
//                    #else
//                    self.currentLocation = real
//                    #endif
//                }
//            }
//        }
//    }
    
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
        
        for route in busRoutes {
            do {
                let response = try await busInfoUseCase.getBusRealTimeInfo(route)
                busRealTimeMap[route] = response
            } catch {
                // 실패 시 기존 값 유지
                print("실시간 버스 조회 실패: \(route), \(error)")
            }
        }
        
        busRealTimeInfos = busRoutes.compactMap { busRealTimeMap[$0] }
    }
    
    // MARK: - Subway Polling
    
    private func startSubwayPolling() {
        stopSubwayPolling()
        
        subwayPollingTask = Task { [weak self] in
            guard let self else { return }
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                if Task.isCancelled { break }
                await self.refreshAllSubwayRealTime()
            }
        }
    }
    
    private func stopSubwayPolling() {
        subwayPollingTask?.cancel()
        subwayPollingTask = nil
    }
    
    @MainActor
    private func refreshAllSubwayRealTime() async {
        guard !subwayRoutes.isEmpty else { return }
        
        for route in subwayRoutes {
            do {
                let infos = try await subwayInfoUseCase.subwayRealTimeInfo(.init(routeName: route))
                
                // 성공한 route만 교체 (실패하면 기존 유지)
                subwayRealTimeInfos.removeAll { $0.routeName == route }
                subwayRealTimeInfos.append(contentsOf: infos)
            } catch {
                // 실패 시 기존 유지
                print("실시간 지하철 조회 실패: \(route), \(error)")
            }
        }
    }
}
