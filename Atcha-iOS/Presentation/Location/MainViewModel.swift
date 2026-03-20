//
//  MainViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation
import Combine
import UIKit
import TMapSDK

final class MainViewModel: BaseViewModel{
    private var alarmTimerCancellable: AnyCancellable?
    private var alarmTimeoutCancellable: AnyCancellable?
    private var alarmObserver: NSObjectProtocol?
    private var refreshUpdateToken: NSObjectProtocol?
    
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var address: String?
    @Published var taxiFare: Double?
    @Published var isServiceRegion: Bool?
    
    @Published var legInfo: LegInfo?
    @Published var addressDesc: String?
    
    @Published var departureTime: String?
    @Published var busRealTimeInfo: BusRealTimeInfo?
    
    @Published var bottomType: MapBottomType?
    @Published var showLockView: Bool = false
    
    @Published var departureStr: String?
    //    @Published var currentCourse: CLLocationDirection?
    @Published var deviceHeading: CLLocationDirection?
    private let headingManager = HeadingManager()
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let fetchTaxiFareUseCase: FetchTaxiFareUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private let locationStateHolder: LocationStateHolder
    private let busInfoUseCase: BusInfoUseCase
    private let alarmUseCase: AlarmUseCase
    private let courseUseCase: CourseUseCase
    
    private var streamTask: Task<Void, Never>?
    
    var routeHandler: ((MainRoute) -> Void)?
    var courseSearchResultHandler: ((String, LegInfo) -> Void)?
    @Published private(set) var lastReverseGeocode: Location?
    
    @Published var showLocationDeniedAlert: Bool = false
    @Published var isGuest: Bool = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.isGuest.rawValue) ?? false
    private var didSendInitialLocation = false
    private let smoother = LocationSmoother(limit: 5)
    private var lastValidTime: Date? = nil
    private var consecutiveValidCount = 0
    
    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "ko_KR") // 혹은 .current
        return formatter
    }()
    private var cachedPathCoordinates: [CLLocationCoordinate2D] = []
    
    init(authorizationUseCase: RequestLocationAuthorizationUseCase,
         streamUseCase: ObserveLocationStreamUseCase,
         fetchTaxiFareUseCase: FetchTaxiFareUseCase,
         searchAddressUseCase: SearchAddressUseCase,
         locationStateHolder: LocationStateHolder,
         busInfoUseCase: BusInfoUseCase,
         alarmUseCase: AlarmUseCase,
         courseUseCase: CourseUseCase) {
        self.authorizationUseCase = authorizationUseCase
        self.streamUseCase = streamUseCase
        self.fetchTaxiFareUseCase = fetchTaxiFareUseCase
        self.searchAddressUseCase = searchAddressUseCase
        self.locationStateHolder = locationStateHolder
        self.busInfoUseCase = busInfoUseCase
        self.alarmUseCase = alarmUseCase
        self.courseUseCase = courseUseCase
        
        super.init()
        observeGlobalRefresh()
        restoreAlarmState()
        self.bind()
    }
    
    func bind() {
        // 1. currentLocation은 주소 검색을 하지 않고 마커 이동 용도로만 둡니다.
        $currentLocation
            .compactMap { $0 }
            .removeDuplicates()
            .sink { _ in }
            .store(in: &cancellables)
        
        // 2. selectedLocation(지도의 중심)이 바뀔 때만 주소를 검색합니다!
        $selectedLocation
            .compactMap { $0 }
            .removeDuplicates()
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] loc in
                guard let self = self else { return }
                Task {
                    await self.updateAddressOnly(for: loc)
                    await self.refreshRegionAndFareForCurrentAddress()
                }
            }
            .store(in: &cancellables)
        $isGuest
            .removeDuplicates()
            .sink { [weak self] guest in
                guard let self = self, !guest else { return } // 게스트에서 회원으로 바뀐 경우만
                Task { await self.refreshRegionAndFareForCurrentAddress() }
            }
            .store(in: &cancellables)
        
        UserDefaultsWrapper.shared.legInfoPublisher
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] newInfo in
                guard let self = self else { return }
                
                if self.legInfo != newInfo {
                    self.drawRoute(address: self.addressDesc, info: newInfo)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateAddressOnly(for location: CLLocationCoordinate2D) async {
        do {
            let info = try await fetchCurrentAddress(lat: location.latitude, lon: location.longitude)
            self.lastReverseGeocode = info
            self.address = info?.name?.isEmpty == false ? info?.name : info?.address
        } catch { print("❌ 역지오코딩 실패: \(error)") }
    }
    
    func refreshRegionAndFareForCurrentAddress() async {
        self.taxiFare = nil
        guard let lat = lastReverseGeocode?.lat,
              let lon = lastReverseGeocode?.lon else { return }
        
        // 서비스지역 먼저 (비회원도 이건 알아야 하므로 유지)
        do {
            let okReq = CheckServiceRegionRequest(lat: lat, lon: lon)
            let ok = try await searchAddressUseCase.checkServiceRegion(okReq)
            await MainActor.run { self.isServiceRegion = ok }
        } catch { print("서비스 지역 확인 실패: \(error)") }
        
        
        guard self.isServiceRegion == true, !isGuest else { return }
        let req = FetchTaxiFareRequest(
            originLat: lastReverseGeocode?.lat,
            originLon: lastReverseGeocode?.lon,
            destinationLat: UserDefaultsWrapper.shared.double(forKey: UserDefaultsWrapper.Key.homeLat.rawValue),
            destinationLon: UserDefaultsWrapper.shared.double(forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
        )
        do {
            let fare = try await fetchTaxiFare(request: req)
            await MainActor.run { self.taxiFare = fare }
        } catch { print("택시비 조회 실패: \(error)") }
    }

    func drawRoute(address: String?, info: LegInfo?) {
        
        guard let address, let info else { return }
        addressDesc = address
        legInfo = info
        
        let wrapper = UserDefaultsWrapper.shared
        wrapper.set(address, forKey: UserDefaultsWrapper.Key.addressDesc.rawValue)
        wrapper.set(info, forKey: UserDefaultsWrapper.Key.legInfo.rawValue)
        setupLegInfo(info: info)
    }
    
    private func setupLegInfo(info: LegInfo?) {
        guard let info,
              let departureStr = info.pathInfo.first?.departureDateTime,
              let totalTime = info.trafficInfo.first?.totalTime else { return }
        
        self.departureStr = departureStr
        
        UserDefaultsWrapper.shared.set(info, forKey: UserDefaultsWrapper.Key.legInfo.rawValue)
        
        guard let departureDate = Self.isoDateFormatter.date(from: departureStr) else { return }
        let minutes = parseTotalTimeToMinutes(totalTime)
        guard let arrivalDate = Calendar.current.date(byAdding: .minute, value: minutes, to: departureDate) else { return }
        
        let wrapper = UserDefaultsWrapper.shared
        let savedArrival = wrapper.object(forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue, of: Date.self)
        
        
        if savedArrival != arrivalDate {
            AlarmManager.shared.scheduleArrivalTimeout(at: arrivalDate)
            wrapper.set(departureStr, forKey: UserDefaultsWrapper.Key.departureTime.rawValue)
            wrapper.set(arrivalDate, forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue)
            self.cachedPathCoordinates = info.pathInfo.flatMap { convertShapeToCoords($0.passShape ?? "") }
        }
    }
    
    private func parseTotalTimeToMinutes(_ time: String) -> Int {
        var totalMinutes = 0
        
        if let hourMatch = time.range(of: "\\d+(?=시간)", options: .regularExpression),
           let hour = Int(time[hourMatch]) {
            totalMinutes += hour * 60
        }
        
        if let minuteMatch = time.range(of: "\\d+(?=분)", options: .regularExpression),
           let minute = Int(time[minuteMatch]) {
            totalMinutes += minute
        }
        
        return totalMinutes
    }
    
    func removeLegInfoAndAddress() {
        let wrapper = UserDefaultsWrapper.shared
        wrapper.remove(forKey: UserDefaultsWrapper.Key.legInfo.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.startLat.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.startLon.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.startAddress.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.departureTime.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue)
    }
    
    func requestPermissionAndStartTracking() {
        Task {
            let status = await authorizationUseCase.askLocationPermission()
            guard status == .authorizedAlways || status == .authorizedWhenInUse else {
                let hasShown = UserDefaults.standard.bool(forKey: "hasShownMainLocationAlert")
                if (status == .denied || status == .restricted) && !hasShown {
                    UserDefaults.standard.set(true, forKey: "hasShownMainLocationAlert")
                    await MainActor.run { self.showLocationDeniedAlert = true }
                }
                return
            }
            
            self.startHeading()
            streamTask?.cancel()
            
            streamTask = Task {
                for await location in streamUseCase.startUpdate() {
                    let now = Date()
                    // 앱 최초 실행 시 빠른 위치 탐색을 위해 nil이면 999.0(강제 탈출 모드) 세팅
                    let isInitialTracking = !self.didSendInitialLocation
                    
                    let timeGap = self.lastValidTime != nil ? now.timeIntervalSince(self.lastValidTime!) : 999.0
                    let isRecovering = timeGap > 60.0
                    
                    let accuracyThreshold: CLLocationAccuracy
                    
                    if isInitialTracking {
                        accuracyThreshold = 1000.0 // 시청 탈출용 널널한 기준
                    } else {
                        accuracyThreshold = isRecovering ? 300.0 : 150.0 // 회원님의 지하철 복구 로직 유지!
                    }
                    
                    // 정확도 필터링
                    guard location.horizontalAccuracy < accuracyThreshold else {
                        self.consecutiveValidCount = 0
                        continue
                    }
                    
                    if isRecovering {
                        self.consecutiveValidCount += 1
                        let requiredCount = isInitialTracking ? 1 : 3
                        
                        if self.consecutiveValidCount >= requiredCount {
                            smoother.reset(location.coordinate)
                            
                            self.lastValidTime = now
                            self.consecutiveValidCount = 0
                        } else {
                            continue
                        }
                    } else {
                        self.lastValidTime = now
                        self.consecutiveValidCount = 0
                    }
                    // 이동 평균 필터링 (항상 적용하여 부드러운 움직임 확보)
                    let smoothedCoord = smoother.smooth(location.coordinate)
                    
                    var finalCoord = smoothedCoord
                    
                    // 알람이 울린 후(`isAlarmFired`)에만 경로 스냅 적용
                    let isAlarmFired = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue) ?? false
                    
                    if isAlarmFired && !self.cachedPathCoordinates.isEmpty {
                        finalCoord = smoother.snap(current: smoothedCoord, polyline: self.cachedPathCoordinates)
                    }
                    
                    let capturedCoord = finalCoord
                    
                    await MainActor.run {
                        self.currentLocation = capturedCoord
                        if !didSendInitialLocation {
                            self.selectedLocation = capturedCoord
                            didSendInitialLocation = true
                        }
                        HomeArrivalManager.shared.checkHomeArrival(currentCoord: capturedCoord)
                    }
                }
            }
        }
    }
    
    func refreshDepatrueTime() {
        Task {
            do {
                let info = try await realodDepartureTime()
                departureTime = info.departureTime
            } catch {
                print("도착 시간 실시간 조회 실패")
            }
        }
    }
    
    private func observeGlobalRefresh() {
        guard refreshUpdateToken == nil else { return }
        
        refreshUpdateToken = NotificationCenter.default.addObserver(
            forName: .refreshDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] noti in
            guard let self else { return }
            self.handleRefreshNotification(noti)
        }
    }
    
    override func handleRefreshNotification(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
              let isReal = userInfo["isReal"] as? String,
              let body = userInfo["body"] as? String,
              let _ = userInfo["updatedAt"] as? String else {
            return
        }
        
        if isReal == "true" {
            AlarmManager.shared.scheduleLocalNotification(from: body, title: "출발 약 10분 전 이에요.", body: "")
        }
        
        let wrapper = UserDefaultsWrapper.shared
        wrapper.set(body, forKey: UserDefaultsWrapper.Key.departureTime.rawValue)
        
        fetchDetailRoute()
        startAlarmTimer()
        checkAlarmTime()
        
        departureTime = body
    }
    
    private func fetchDetailRoute() {
        let wrapper = UserDefaultsWrapper.shared
        let routeId = wrapper.string(forKey: UserDefaultsWrapper.Key.lastRouteId.rawValue) ?? ""
        
        Task {
            do {
                let info = try await courseUseCase.courseSearch(routeId)
                let pathinfo = info.toLegPathInfos()
                let trafficInfo = info.toLegTrafficInfos()
                let busInfo = info.toBusInfos()
                
                let legInfo: LegInfo = LegInfo(pathInfo: pathinfo,
                                               trafficInfo: trafficInfo,
                                               busInfo: busInfo)
                wrapper.set(legInfo, forKey: UserDefaultsWrapper.Key.legInfo.rawValue)
                self.drawRoute(address: self.addressDesc, info: legInfo)
            } catch {
                print("routeId 조회 대실패 ㅠㅠ!!")
            }
        }
    }
    
    // MARK: - 알림 취소
    func alarmDelete() {
        
        stopAlarmTimer()
        
        AlarmManager.shared.cancelArrivalTimeout()
        
        let wrapper = UserDefaultsWrapper.shared
        let savedLastRouteId: String? = wrapper.string(
            forKey: UserDefaultsWrapper.Key.lastRouteId.rawValue)
        let request = AlarmRequest(lastRouteId: savedLastRouteId)
        Task {
            do {
                let _ = try await alarmUseCase.alarmDelete(request)
                wrapper.remove(forKey: UserDefaultsWrapper.Key.lastRouteId.rawValue)
                print("알람 취소 성공")
                
            } catch {
                print("알람 취소 실패: \(error)")
            }
        }
        
        UserDefaultsWrapper.shared.set(
            false,
            forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue
        )
    }
    
    func setupLocation() {
        requestPermissionAndStartTracking()
    }
    
    func stopHeading() {
        headingManager.stop()
    }
    
    func stopTracking() {
        streamTask?.cancel()
        streamUseCase.stopUpdate()
        headingManager.stop()
    }
    
    func startHeading() {
        headingManager.onHeading = { [weak self] h in
            DispatchQueue.main.async { self?.deviceHeading = h }
        }
        headingManager.start()
    }
    
    deinit {
        stopTracking()
        if let alarmObserver { NotificationCenter.default.removeObserver(alarmObserver) }
        if let refreshUpdateToken { NotificationCenter.default.removeObserver(refreshUpdateToken) }
    }
    
    func resetLocationState() {
        self.lastValidTime = nil
        self.didSendInitialLocation = false
        self.consecutiveValidCount = 0
        self.currentLocation = nil
        self.selectedLocation = nil
        self.streamTask?.cancel()
    }
    
    func forceLocationSnap() {
        self.didSendInitialLocation = false
        self.lastValidTime = nil
        self.consecutiveValidCount = 0
    }
}

// MARK: - Alarm
extension MainViewModel {
    private func checkAlarmTime() {
        let wrapper = UserDefaultsWrapper.shared
        
        if wrapper.bool(forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue) ?? false {
            stopAlarmTimer()
            return
        }
        
        if let departureTime: String = wrapper.string(forKey: UserDefaultsWrapper.Key.departureTime.rawValue) {
            print("departureTime : \(departureTime)")
            if isInAlarmRange(dateString: departureTime) {
                // TODO: 알림 이후 등록이 되는지확인
                showLockView = true
                AlarmManager.shared.startAlarm(title: "눌러서 출발 알람 끄기",
                                               body: "자리에서 일어나야 할 시간이에요!")
                //                startAlarmTimeoutTimer()
                stopAlarmTimer()
            } else {
                print("미래")
            }
        } else {
            print("값 없음")
        }
    }
    
    private func isInAlarmRange(dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = .current
        
        guard let alarmDate = formatter.date(from: dateString) else {
            print("날짜 파싱 실패")
            return false
        }
        
        let now = Date()
        let oneMinuteBefore = alarmDate
        
        return now >= oneMinuteBefore
    }
    
    func startAlarmTimer() {
        let wrapper = UserDefaultsWrapper.shared
        if wrapper.bool(forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue) ?? false {
            return
        }
        
        alarmTimerCancellable = Timer
            .publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAlarmTime()
            }
    }
    
    private func stopAlarmTimer() {
        alarmTimerCancellable?.cancel()
        alarmTimerCancellable = nil
    }
}


// MARK: - Router
extension MainViewModel {
    func handleRoute(route: MainRoute) {
        switch route {
        case .changeHome:
            routeHandler?(.changeHome)
        case .changeCourse:
            routeHandler?(.changeCourse(location: Location(
                name: lastReverseGeocode?.name,
                lat: lastReverseGeocode?.lat ?? 0.0,
                lon: lastReverseGeocode?.lon ?? 0.0,
                businessCategory: lastReverseGeocode?.businessCategory,
                address: lastReverseGeocode?.address,
                radius: lastReverseGeocode?.radius)))
            
        case .courseSearch(let startLat, let startLon, _, _):
            
            routeHandler?(.courseSearch(
                startLat: (lastReverseGeocode?.lat).map { String($0) } ?? startLat,
                startLon: (lastReverseGeocode?.lon).map { String($0) } ?? startLon,
                startAddress: address ?? lastReverseGeocode?.address ?? "",
                context: .beforeRegister
            ))
            
        case .myPage:
            routeHandler?(.myPage)
            
        case .detailRoute:
            let wrapper = UserDefaultsWrapper.shared
            guard let info = wrapper.object(forKey: UserDefaultsWrapper.Key.legInfo.rawValue,
                                            of: LegInfo.self),
                  let addressDesc = wrapper.string(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue) else { return }
            routeHandler?(.detailRoute(address: addressDesc,
                                       infos: info,
                                       context: .afterReigster))
        case .lockScreen:
            guard let address, let legInfo else { return }
            routeHandler?(.lockScreen(info: legInfo, address: address))
        case .proximity:
            routeHandler?(.proximity)
        case .dismissLockScreen:
            routeHandler?(.dismissLockScreen)
        case .loginSheet:
            routeHandler?(.loginSheet)
        }
    }
}

// MARK: - Bindigs
extension MainViewModel {
    private func handleLocationUpdate(_ location: CLLocationCoordinate2D?) {
        guard let location else {
            print("위치 무효 또는 경로 이미 존재")
            return
        }
        
        Task {
            await checkServiceRegion(currentLocation: location)
            await updateAddressAndFare(for: location)
        }
    }
    
    private func updateAddressAndFare(for location: CLLocationCoordinate2D) async {
        do {
            let info = try await fetchCurrentAddress(lat: location.latitude, lon: location.longitude)
            self.lastReverseGeocode = info
            
            address = info?.name?.isEmpty == false ? info?.name : info?.address
            
            let request = FetchTaxiFareRequest(
                originLat: info?.lat,
                originLon: info?.lon,
                destinationLat: UserDefaultsWrapper.shared.double(forKey: UserDefaultsWrapper.Key.homeLat.rawValue),
                destinationLon: UserDefaultsWrapper.shared.double(forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
            )
            
            taxiFare = try? await fetchTaxiFare(request: request)
        } catch {
            print("주소 또는 요금 정보 업데이트 실패: \(error)")
        }
    }
    
    func fetchFareForRegisteredStart() async throws -> Double {
        let w = UserDefaultsWrapper.shared
        let latStr: String = w.string(forKey: UserDefaultsWrapper.Key.startLat.rawValue) ?? ""
        let lonStr: String = w.string(forKey: UserDefaultsWrapper.Key.startLon.rawValue) ?? ""
        
        guard let lat = Double(latStr), let lon = Double(lonStr) else {
            throw NSError(domain: "StartCoord", code: -1, userInfo: [NSLocalizedDescriptionKey: "저장된 출발 좌표가 유효하지 않습니다."])
        }
        
        let req = FetchTaxiFareRequest(
            originLat: lat,
            originLon: lon,
            destinationLat: w.double(forKey: UserDefaultsWrapper.Key.homeLat.rawValue),
            destinationLon: w.double(forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
        )
        return try await fetchTaxiFare(request: req)
    }
    
    // MARK: - 서비즈 지역 확인
    private func checkServiceRegion(currentLocation: CLLocationCoordinate2D) async {
        let req = CheckServiceRegionRequest(lat: currentLocation.latitude, lon: currentLocation.longitude)
        
        do {
            isServiceRegion = try await searchAddressUseCase.checkServiceRegion(req)
        } catch {
            print("서비스 지역 확인 실패:", error)
        }
    }
    
    func refreshCurrentMapCenterData() {
        Task {
            await self.refreshRegionAndFareForCurrentAddress()
        }
    }
}

// MARK: - Network
extension MainViewModel {
    private func fetchCurrentAddress(lat: Double, lon: Double) async throws -> Location? {
        let request: ReverseGeocodeLocationRequest = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await searchAddressUseCase.searchLocation(request)
    }
    
    private func fetchTaxiFare(request: FetchTaxiFareRequest) async throws -> Double {
        return try await fetchTaxiFareUseCase.fetchTaxiFare(request: request)
    }
    
    private func realodDepartureTime() async throws -> AlarmRefresh {
        return try await alarmUseCase.alarmRefresh()
    }
}

extension MainViewModel {
    func stopAlarmTimeoutTimer() {
        alarmTimeoutCancellable?.cancel()
        alarmTimeoutCancellable = nil
    }
}

extension MainViewModel {
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

extension MainViewModel {
    func restoreAlarmState() {
        let wrapper = UserDefaultsWrapper.shared
        
        // 1. 알람이 등록되어 있는지 확인
        guard wrapper.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue) == true else { return }
        
        // 2. 데이터 가져오기
        guard let departureStr = wrapper.string(forKey: UserDefaultsWrapper.Key.departureTime.rawValue),
              let arrivalDate = wrapper.object(forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue, of: Date.self) else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        
        guard let departureDate = formatter.date(from: departureStr) else { return }
        
        let now = Date()
        let timeoutDate = arrivalDate.addingTimeInterval(10 * 60)
        
        // --- 분기 처리 ---
        
        if now < departureDate {
            // [Case 1] 아직 출발 전
            startAlarmTimer()
            
        } else if now >= departureDate && now < timeoutDate {
            // [Case 2] 이동 중 (핵심!)
            
            // 중요: 이미 알람이 울린 것으로 간주하여 플래그 세팅 (경로 스냅핑 활성화)
            wrapper.set(true, forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue)
            AlarmManager.shared.scheduleArrivalTimeout(at: arrivalDate)
            // 소리 알람(AlarmManager.startAlarm)은 호출하지 않음!
            self.showLockView = false // 잠금화면 보이지 않음
            self.bottomType = .departure // 하단 바를 '안내 중' 상태로 변경
            
            
            if let current = self.currentLocation {
                HomeArrivalManager.shared.checkHomeArrival(currentCoord: current)
            }
            
        } else if now >= timeoutDate {
            // [Case 3] 이미 한참 지남
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: NSNotification.Name("scheduledArrivalDidTimeout"), object: nil)
            }
        }
    }
}
