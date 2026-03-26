//
//  DetailRouteViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import Foundation
import UIKit
import CoreLocation
import MapKit

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
    
    var infos: LegInfo
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
    
    @Published var subwayRealTimeInfos: [SubwayRealTimeInfo] = []
    private var subwayRoutes: [String] = []
    
    @Published private(set) var context: DetailRouteContext
    @Published var nearLegIDs: Set<UUID> = []
    @Published var departedLegIDs: Set<UUID> = []
    
    @Published var deviceHeading: CLLocationDirection?
    private let headingManager = HeadingManager()
    
    private let smoother = LocationSmoother(limit: 5)
    @Published var legPolylineById: [UUID: [CLLocationCoordinate2D]] = [:]
    
    private var pollingTask: Task<Void, Never>?
    @Published var isRefreshing: Bool = false
    
    private var lastValidTime: Date? = nil
    private var didSendInitialLocation = false
    
    private var consecutiveValidCount = 0
    
    private var isCalculatingProximity = false
    
    func forceLocationSnap() {
        self.didSendInitialLocation = false
        self.lastValidTime = nil
        self.consecutiveValidCount = 0
    }
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
        bindUserDefaults()
    }
    
    private func bindUserDefaults() {
        UserDefaultsWrapper.shared.legInfoPublisher
            .compactMap { $0 } // nil이 아닐 때만
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] newInfo in
                print("새로운 경로 정보 감지됨: UI 업데이트 시작")
                self?.updateWithNewInfo(newInfo)
            }
            .store(in: &cancellables)
    }
    
    private func updateWithNewInfo(_ info: LegInfo) {
        // 1. 데이터 갱신
        self.infos = info
        self.legtPathInfo = info.pathInfo
        self.legTrafficInfo = info.trafficInfo
        
        // 2. 경로선 다시 그리기 위해 딕셔너리 갱신 로직 등 실행
        self.fetchInfo()
    }
    
    func fetchInfo() {
        legtPathInfo = infos.pathInfo
        legTrafficInfo = infos.trafficInfo
        
        var dict: [UUID: [CLLocationCoordinate2D]] = [:]
        for (traffic, path) in zip(legTrafficInfo, legtPathInfo) {
            if let shape = path.passShape, !shape.isEmpty {
                dict[traffic.id] = self.convertShapeToCoords(shape)
                continue
            }
            if let steps = path.step, !steps.isEmpty {
                let merged = steps.compactMap { $0.linestring }.filter { !$0.isEmpty }.joined(separator: " ")
                if !merged.isEmpty {
                    dict[traffic.id] = self.convertShapeToCoords(merged)
                }
            }
        }
        self.legPolylineById = dict
        
        guard context == .afterReigster else { return }
        
        setupRoutes()
        startPolling()
    }
    
    private func setupRoutes() {
        let routes = infos.busInfo
            .compactMap { $0.routeName }
            .filter { !$0.isEmpty && $0.contains(":") }
        busRoutes = Array(Set(routes))
        
        subwayRoutes = Array(Set(
            infos.trafficInfo
                .filter { $0.mode == .subway }
                .compactMap { $0.route }
                .filter { !$0.isEmpty }
        ))
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
    func refreshAllRealTimeData() async {
        guard !isRefreshing else { return }
        guard !busRoutes.isEmpty || !subwayRoutes.isEmpty else { return }
        
        isRefreshing = true // 애니메이션 시작 신호
        
        // async let을 사용하여 버스와 지하철 정보를 동시에(병렬) 요청함 (속도 최적화)
        async let refreshBus: () = refreshAllBusRealTime()
        async let refreshSubway: () = refreshAllSubwayRealTime()
        
        _ = await [refreshBus, refreshSubway]
        
        // 애니메이션이 시각적으로 잘 보이도록 최소 0.5초 대기 후 종료
        try? await Task.sleep(nanoseconds: 500_000_000)
        isRefreshing = false
    }
    
    private func startPolling() {
        let isFired = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue) ?? false
        guard isFired else {
            print("알람이 등록되지 않은 상태이므로 폴링을 시작하지 않습니다.")
            return
        }
        
        stopPolling()
        
        pollingTask = Task { [weak self] in
            guard let self = self else { return }
            
            // 1. 진입 시 최초 1회 즉시 실행
            await self.refreshAllRealTimeData()
            
            while !Task.isCancelled {
                // 2. 15초 대기
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                
                // 3. 루프 중간에 취소 여부 및 알람 등록 상태 재확인
                let isRegistered = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue) ?? false
                if !isRegistered || Task.isCancelled {
                    self.stopPolling()
                    break
                }
                
                // 4. 통합 데이터 새로고침 실행
                await self.refreshAllRealTimeData()
            }
        }
    }
    
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
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
                    let now = Date()
                    
                    let isInitialTracking = !self.didSendInitialLocation
                    
                    let timeGap = self.lastValidTime != nil ? now.timeIntervalSince(self.lastValidTime!) : 999.0
                    let isRecovering = timeGap > 60.0
                    
                    let accuracyThreshold: CLLocationAccuracy
                    
                    if isInitialTracking {
                        accuracyThreshold = 1000.0 // 시청 탈출용 널널한 기준
                    } else {
                        accuracyThreshold = isRecovering ? 300.0 : 150.0 // 회원님의 지하철 복구 로직 유지!
                    }
                    
                    guard location.horizontalAccuracy < accuracyThreshold else {
                        self.consecutiveValidCount = 0
                        continue
                    }
                    
                    if isRecovering {
                        // 지상 탈출이 의심될 때: 바로 안 믿고 카운터를 올립니다.
                        self.consecutiveValidCount += 1
                        
                        let requiredCount = isInitialTracking ? 1 : 3
                        
                        if self.consecutiveValidCount >= requiredCount {
                            // 3번 연속(약 3초) 정상 신호가 들어왔다? 이건 100% 진짜 지상이다!
                            smoother.reset(location.coordinate)
                            
                            // 리셋했으니 이제 평상시 상태로 복구
                            self.lastValidTime = now
                            self.consecutiveValidCount = 0
                        } else {
                            // 아직 1~2번만 들어왔으면 마커를 움직이지 않고 무시 (가짜일 수 있으므로 대기)
                            continue
                        }
                    } else {
                        // 평상시 (지상에서 잘 걸어 다니고 있을 때)
                        self.lastValidTime = now
                        self.consecutiveValidCount = 0 // 평소엔 카운터 필요 없음
                    }
                    
                    // 항상 Smoothing 적용
                    let smoothedCoord = smoother.smooth(location.coordinate)
                    
                    var finalCoord = smoothedCoord
                    
                    // 알람이 울린 상태라면 스냅 적용
                    let isAlarmFired = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue) ?? false
                    
                    if isAlarmFired && !legtPathInfo.isEmpty {
                        let allCoords = legtPathInfo.flatMap { convertShapeToCoords($0.passShape ?? "") }
                        finalCoord = smoother.snap(current: smoothedCoord, polyline: allCoords)
                    }
                    
                    let capturedCoord = finalCoord
                    
                    await MainActor.run {
                        self.currentLocation = capturedCoord
                        if !self.didSendInitialLocation {
                            self.didSendInitialLocation = true
                        }
                        HomeArrivalManager.shared.checkHomeArrival(currentCoord: capturedCoord)
                    }
                    
                    self.calculateProximity(coord: finalCoord)
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
        stopPolling()
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
                if checkAndStopPolling(error: error) { break }
            }
        }
        
        busRealTimeInfos = busRoutes.compactMap { busRealTimeMap[$0] }
    }
    
    // MARK: - Subway Polling
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
                if checkAndStopPolling(error: error) { break }
            }
        }
    }
}

extension DetailRouteViewModel {
    private func convertShapeToCoords(_ shape: String) -> [CLLocationCoordinate2D] {
        shape.split(separator: " ").compactMap { pair in
            let parts = pair.split(separator: ",")
            guard parts.count == 2,
                  let lon = Double(parts[0]),
                  let lat = Double(parts[1]) else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
}

extension DetailRouteViewModel {
    /// 현재 좌표를 기준으로 가장 가까운 경로를 찾아 nearLegIDs를 업데이트합니다.
    func calculateProximity(coord: CLLocationCoordinate2D?) {
        guard let coord = coord, !isCalculatingProximity else { return }
        
        isCalculatingProximity = true
        
        let threshold: CLLocationDistance = 150
        let polylines = self.legPolylineById
        let orderedLegs = self.legTrafficInfo
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var nearCandidates = Set<UUID>()
            
            for (id, polyline) in polylines {
                let d = self.distanceToPolylineMeters(point: coord, polyline: polyline)
                if d <= threshold {
                    nearCandidates.insert(id)
                }
            }
            
            var picked: Set<UUID> = []
            if let first = orderedLegs.first(where: { nearCandidates.contains($0.id) })?.id {
                picked = [first]
            }
            
            var departed: Set<UUID> = []
            if let activeID = picked.first,
               let leg = orderedLegs.first(where: { $0.id == activeID }),
               let firstStop = leg.passStopList?.first,
               let latStr = firstStop.lat, let lat = Double(latStr),
               let lonStr = firstStop.lon, let lon = Double(lonStr) {
                
                let startLoc = CLLocation(latitude: lat, longitude: lon)
                let currentLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                
                // 첫 정류장에서 300m 이상 벗어났다면 '출발(탑승)'한 것으로 간주
                if currentLoc.distance(from: startLoc) > 300 {
                    departed.insert(activeID)
                }
            }
            
            DispatchQueue.main.async {
                self.nearLegIDs = picked
                self.departedLegIDs = departed
                self.isCalculatingProximity = false
            }
        }
    }
    
    // 뷰컨트롤러에서 가져온 거리 계산 함수
    private func distanceToPolylineMeters(
        point: CLLocationCoordinate2D,
        polyline: [CLLocationCoordinate2D]
    ) -> CLLocationDistance {
        guard polyline.count >= 2 else { return .greatestFiniteMagnitude }
        
        let p = MKMapPoint(point)
        var best = CLLocationDistance.greatestFiniteMagnitude
        
        for i in 0..<(polyline.count - 1) {
            let a = MKMapPoint(polyline[i])
            let b = MKMapPoint(polyline[i + 1])
            
            let abx = b.x - a.x
            let aby = b.y - a.y
            let apx = p.x - a.x
            let apy = p.y - a.y
            
            let ab2 = abx*abx + aby*aby
            if ab2 == 0 {
                best = min(best, p.distance(to: a))
                continue
            }
            
            var t = (apx*abx + apy*aby) / ab2
            t = max(0, min(1, t))
            
            let closest = MKMapPoint(x: a.x + t*abx, y: a.y + t*aby)
            best = min(best, p.distance(to: closest))
        }
        
        return best
    }
}


extension DetailRouteViewModel {
    private func checkAndStopPolling(error: Error) -> Bool {
        if let apiError = error as? APIError {
            if case .serverError(_, let code) = apiError {
                let stopCodes = ["URT_001", "LRT_001", "LRT_003", "REQ_004"]
                
                if let code = code, stopCodes.contains(code) {
                    self.stopPolling()
                    return true
                }
            }
        }
        return false
    }
}
