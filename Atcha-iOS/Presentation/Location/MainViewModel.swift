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
    
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var address: String?
    @Published var taxiFare: Double?
    
    @Published var legInfo: LegInfo?
    @Published var addressDesc: String?
    @Published var busRealTimeInfo: BusRealTimeInfo?
    
    @Published var bottomType: MapBottomType?
    @Published var showLockView: Bool = false
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let fetchTaxiFareUseCase: FetchTaxiFareUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private let locationStateHolder: LocationStateHolder
    private let busInfoUseCase: BusInfoUseCase
    private var streamTask: Task<Void, Never>?
    
    var routeHandler: ((MainRoute) -> Void)?
    var courseSearchResultHandler: ((String, LegInfo) -> Void)?
    
    init(authorizationUseCase: RequestLocationAuthorizationUseCase,
         streamUseCase: ObserveLocationStreamUseCase,
         fetchTaxiFareUseCase: FetchTaxiFareUseCase,
         searchAddressUseCase: SearchAddressUseCase,
         locationStateHolder: LocationStateHolder,
         busInfoUseCase: BusInfoUseCase) {
        self.authorizationUseCase = authorizationUseCase
        self.streamUseCase = streamUseCase
        self.fetchTaxiFareUseCase = fetchTaxiFareUseCase
        self.searchAddressUseCase = searchAddressUseCase
        self.locationStateHolder = locationStateHolder
        self.busInfoUseCase = busInfoUseCase
        
        super.init()
        self.bind()
        self.startAlarmTimer()
    }
    
    func bind() {
        $currentLocation
            .removeDuplicates()
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
    }
    
    func drawRoute(address: String?, info: LegInfo?) {
        guard let address, let info else { return }
        addressDesc = address
        legInfo = info
        
        let wrapper = UserDefaultsWrapper.shared
        wrapper.set(address, forKey: UserDefaultsWrapper.Key.addressDesc.rawValue)
        wrapper.set(info, forKey: UserDefaultsWrapper.Key.legInfo.rawValue)
        
        guard let time = legInfo?.pathInfo.first?.departureDateTime else {
            return
        }
        print("time : \(time)")
        wrapper.set(time, forKey: UserDefaultsWrapper.Key.departureTime.rawValue)
        
        AlarmManager.shared.startAlarm(after: time, title: "집에 가자", body: "집에 가자")
    }
    
    func removeLegInfoAndAddress() {
        let wrapper = UserDefaultsWrapper.shared
        wrapper.remove(forKey: UserDefaultsWrapper.Key.legInfo.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.startLat.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.startLon.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.startAddress.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.departureTime.rawValue)
    }
    
    func requestPermissionAndStartTracking() {
        Task {
            let status = await authorizationUseCase.askLocationPermission()
            guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
            
            streamTask = Task {
                var didSendInitialLocation = false
                for await location in streamUseCase.startUpdate() {
                    let currentLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    
                    if !didSendInitialLocation {
                        self.currentLocation = currentLocation
                        didSendInitialLocation = true
                    }
                    
                    selectedLocation = currentLocation
                }
            }
        }
    }
    
    func getBusRealTime() {
        guard let legInfo else { return }
        
        if let firstNonWalkMode = legInfo.pathInfo.first(where: { $0.mode != .walk }) {
            print("최초의 walk 제외 mode: \(firstNonWalkMode.mode?.rawValue ?? "없음")")
            if firstNonWalkMode.mode == .bus {
                let busDetailInfo = legInfo.busInfo.filter { $0.routeName?.isEmpty == false }
                if let firstValidInfo = busDetailInfo.first(where: { $0.routeName != nil }) {
                    let request = BusRealTimeInfoRequest(
                        routeName: firstValidInfo.routeName,
                        stationName: firstValidInfo.start?.name,
                        lat: firstValidInfo.start?.lat,
                        lon: firstValidInfo.start?.lon,
                        passStations: firstValidInfo.passStations
                    )
                    
                    Task {
                        do {
                            let info = try await busRealTimeInfo(request: request)
                            self.busRealTimeInfo = info
                        } catch {
                            print("버스 실시간 조회 실패")
                        }
                    }
                }
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
            if !checkFutureTimeOver(dateString: departureTime) {
                let diContainer = LockScreenDIContainer()
                let vm = diContainer.makeLockScreenViewModel()
                let vc = diContainer.makeLockScreenViewController(viewModel: vm)
                vc.modalPresentationStyle = .overFullScreen
                print("과거")
                showLockView = true
                stopAlarmTimer()
            } else {
                print("미래")
            }
        } else {
            print("값 없음")
        }
    }
    
    private func checkFutureTimeOver(dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = .current
        
        guard let inputDate = formatter.date(from: dateString) else {
            print("날짜 파싱 실패")
            return false
        }
        
        let currentDate = Date()
        let timeInterval = inputDate.timeIntervalSince(currentDate)
        let isFuture = timeInterval > 0
        
        return isFuture
    }
    
    func startAlarmTimer() {
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
        case .changeCourse:
            routeHandler?(.changeCourse)
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
            guard let address, let legInfo else { return }
            routeHandler?(.detailRoute(address: address, infos: legInfo))
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
            await updateAddressAndFare(for: location)
        }
    }
    
    private func updateAddressAndFare(for location: CLLocationCoordinate2D) async {
        do {
            let info = try await fetchCurrentAddress(lat: location.latitude, lon: location.longitude)
            
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
    
    private func busRealTimeInfo(request: BusRealTimeInfoRequest) async throws -> BusRealTimeInfo {
        return try await busInfoUseCase.busRealTimeInfo(request)
    }
}
