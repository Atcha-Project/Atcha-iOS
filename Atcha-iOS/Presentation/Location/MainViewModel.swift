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

final class MainViewModel: BaseViewModel {
    private var alarmTimerCancellable: AnyCancellable?
    private var alarmFinishCancellable: AnyCancellable?
    
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
    @Published var pendingToast: String?
    
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
        self.bind()
        //        self.startAlarmTimer()
    }
    
    func bind() {
        $currentLocation
            .compactMap { $0 }
            .removeDuplicates()
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, let loc = self.currentLocation else { return }
                Task { await self.updateAddressOnly(for: loc) }
            }
            .store(in: &cancellables)

        $address
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { await self?.refreshRegionAndFareForCurrentAddress() }
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

    private func refreshRegionAndFareForCurrentAddress() async {
        guard let lat = lastReverseGeocode?.lat,
              let lon = lastReverseGeocode?.lon else { return }

        // 서비스지역 먼저
        do {
            let okReq = CheckServiceRegionRequest(lat: lat, lon: lon)
            let ok = try await searchAddressUseCase.checkServiceRegion(okReq)
            await MainActor.run { self.isServiceRegion = ok }
        } catch { print("서비스 지역 확인 실패: \(error)") }

        // 택시비는 서비스지역 O일 때만
        guard self.isServiceRegion == true else { return }
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
        let routeId = info?.pathInfo.first?.routeId
        print("routeId : \(routeId)")
        
        guard let info, let departureStr = info.pathInfo.first?.departureDateTime,
              let totalTime = info.trafficInfo.first?.totalTime else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = .current
        
        guard let departureDate = formatter.date(from: departureStr) else { return }
        let minutes = parseTotalTimeToMinutes(totalTime)
        
        guard let arrivalDate = Calendar.current.date(byAdding: .minute, value: minutes, to: departureDate) else { return }
        
        print("departureDate : \(departureDate)")
        print("arrivalDate : \(arrivalDate)")
        let wrapper = UserDefaultsWrapper.shared
        wrapper.set(departureStr, forKey: UserDefaultsWrapper.Key.departureTime.rawValue)
        wrapper.set(arrivalDate, forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue)
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
        //        wrapper.remove(forKey: UserDefaultsWrapper.Key.trainRealTime.rawValue)
    }
    
    func requestPermissionAndStartTracking() {
        Task {
            let status = await authorizationUseCase.askLocationPermission()
            let _ = await authorizationUseCase.askPushPermission()
            guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
            
            streamTask = Task {
                var didSendInitialLocation = false
                for await location in streamUseCase.startUpdate() {
                    let currentLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    
                    if !didSendInitialLocation {
                        self.currentLocation = currentLocation
                        didSendInitialLocation = true
                    }
                    
                    //                    getNearstToast(currentLocation: currentLocation)
                    selectedLocation = currentLocation
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
    
    func enqueueToast(_ message: String) {
        pendingToast = message
    }
    
    override func handleRefreshNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let body = userInfo["body"] as? String,
              let _ = userInfo["updatedAt"] as? String else {
            return
        }
        
        fetchDetailRoute()
        //        wrapper.remove(forKey: UserDefaultsWrapper.Key.legInfo.rawValue)
        //
        //        let routeId = legInfo?.pathInfo.first?.routeId ?? ""
        //        Task {
        //            do {
        //                let info = try await courseUseCase.courseSearch(routeId)
        //                let pathinfo = info.toLegPathInfos()
        //                let trafficInfo = info.toLegTrafficInfos()
        //                let busInfo = info.toBusInfos()
        //
        //                let legInfo: LegInfo = LegInfo(pathInfo: pathinfo,
        //                                               trafficInfo: trafficInfo,
        //                                               busInfo: busInfo)
        //                wrapper.set(legInfo, forKey: UserDefaultsWrapper.Key.legInfo.rawValue)
        //                drawRoute(address: addressDesc, info: legInfo)
        //            } catch {
        //                print("routeId 조회 대실패 ㅠㅠ!!")
        //            }
        //        }
        //
        //        wrapper.remove(forKey: UserDefaultsWrapper.Key.departureTime.rawValue)
        UserDefaultsWrapper.shared.set(body, forKey: UserDefaultsWrapper.Key.departureTime.rawValue)
        AlarmManager.shared.startAlarm(after: body,
                                       title: "눌러서 출발 알람 끄기",
                                       body: "자리에서 일어나야 할 시간이에요!")
        
        departureTime = body
    }
    
    private func fetchDetailRoute() {
        let wrapper = UserDefaultsWrapper.shared
        let routeId = legInfo?.pathInfo.first?.routeId ?? ""
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
                drawRoute(address: addressDesc, info: legInfo)
            } catch {
                print("routeId 조회 대실패 ㅠㅠ!!")
            }
        }
        
        //        wrapper.remove(forKey: UserDefaultsWrapper.Key.departureTime.rawValue)
        //        wrapper.set(body, forKey: UserDefaultsWrapper.Key.departureTime.rawValue)
        //
        //        AlarmManager.shared.startAlarm(after: body,
        //                                       title: "눌러서 출발 알람 끄기",
        //                                       body: "자리에서 일어나야 할 시간이에요!")
        //
        //        departureTime = body
    }
    
    // MARK: - 알림 취소
    func alarmDelete() {
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
    }
    
    func setupLocation() {
        requestPermissionAndStartTracking()
    }
    
    func stopTracking() {
        streamTask?.cancel()
        streamUseCase.stopUpdate()
    }
    
    deinit {
        stopTracking()
    }
}

// MARK: - Alarm
extension MainViewModel {
    private func checkAlarmTime() {
        let wrapper = UserDefaultsWrapper.shared
        if let departureTime: String = wrapper.string(forKey: UserDefaultsWrapper.Key.departureTime.rawValue) {
            print("departureTime : \(departureTime)")
            //            if !checkFutureTimeOver(dateString: departureTime) {
            if isInAlarmRange(dateString: departureTime) {
                
                // TODO: 알림 이후 등록이 되는지확인
                showLockView = true
                AlarmManager.shared.startAlarm(after: departureTime,
                                               title: "눌러서 출발 알람 끄기",
                                               body: "자리에서 일어나야 할 시간이에요!")
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
        let oneMinuteBefore = alarmDate.addingTimeInterval(-60) // 60초 전
        
        // 현재가 60초 전과 알람 시간 사이인지 확인
        return now >= oneMinuteBefore && now <= alarmDate
    }
    
    func startAlarmTimer() {
        alarmTimerCancellable = Timer
            .publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAlarmTime()
            }
        
        alarmFinishCancellable = Timer
            .publish(every: 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if let arrivalTime = UserDefaultsWrapper.shared.object(
                    forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue,
                    of: Date.self
                ) {
                    let now = Date()
                    let thirtyMinutesLater = arrivalTime.addingTimeInterval(30 * 60) // 30분 후
                    
                    print("departure Time : \(arrivalTime)")
                    print("30분 후 시각 : \(thirtyMinutesLater)")
                    
                    if now >= thirtyMinutesLater {
                        stopFinishAlarmTimer()
                        bottomType = .search
                    }
                }
            }
    }
    
    func stopAlarmTimer() {
        alarmTimerCancellable?.cancel()
        alarmTimerCancellable = nil
    }
    
    func stopFinishAlarmTimer() {
        alarmFinishCancellable?.cancel()
        alarmFinishCancellable = nil
    }
}

// MARK: - Router
extension MainViewModel {
    func handleRoute(route: MainRoute) {
        switch route {
        case .changeCourse:
            routeHandler?(.changeCourse(location: Location(
                name: lastReverseGeocode?.name,
                lat: lastReverseGeocode?.lat ?? 0.0,
                lon: lastReverseGeocode?.lon ?? 0.0,
                businessCategory: lastReverseGeocode?.businessCategory,
                address: lastReverseGeocode?.address,
                radius: lastReverseGeocode?.radius)))
            
        case .courseSearch:
            guard let currentLocation else { return }
            let lat: String = "\(currentLocation.latitude)"
            let lon: String = "\(currentLocation.longitude)"
            let address: String = address ?? ""
            
            routeHandler?(.courseSearch(startLat: lat,
                                        startLon: lon,
                                        startAddress: address))
        case .myPage:
            routeHandler?(.myPage)
            
        case .detailRoute:
            fetchDetailRoute() // 이걸 통신을 할까 말까
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
        }
    }
}

// MARK: - Bindigs
extension MainViewModel {
    private func handleLocationUpdate(_ location: CLLocationCoordinate2D?) {
        guard let location else {
            print("⛔️ 위치 무효 또는 경로 이미 존재")
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
            print("❌ 주소 또는 요금 정보 업데이트 실패: \(error)")
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
    
//    func setCurrentToSeoulStation() {
//            let seoulStation = CLLocationCoordinate2D(latitude: 37.554722, longitude: 126.970833)
//            // 위치 상태 갱신
//            self.currentLocation = seoulStation
//            self.selectedLocation = seoulStation
//            // 주소/서비스지역/택시비 갱신 트리거
//            Task { await self.updateAddressOnly(for: seoulStation) }
//            // address 퍼블리셔가 이미 region+fare 리프레시를 타도록 bind()에 연결돼 있음
//        }
}


