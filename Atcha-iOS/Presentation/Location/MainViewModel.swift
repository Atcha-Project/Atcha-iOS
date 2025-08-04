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

struct LastTrainInfo {
    let name: String? // 147 or 강남역
    let time: String? // 7분 5초
    let icon: UIImage?
    let remainingSeat: Int? // 몇자리 남았는지
}

final class MainViewModel: BaseViewModel {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var address: String?
    @Published var taxiFare: Double?
    
    @Published var legInfo: LegInfo?
    @Published var addressDesc: String?
    @Published var busRealTimeInfo: BusRealTimeInfo?
    
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
        self.bindView()
    }
    
    func bindView() {
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
        
        let wrapper = UserDefaultsWrapper()
        wrapper.set(address, forKey: UserDefaultsWrapper.Key.addressDesc.rawValue)
        wrapper.set(info, forKey: UserDefaultsWrapper.Key.legInfo.rawValue)
        
        guard let time = legInfo?.pathInfo.first?.departureDateTime else {
            return
        }
        print("time : \(time)")
        AlarmManager.shared.startAlarm(after: time, title: "집에 가자", body: "집에 가자")
    }
    
    func removeLegInfoAndAddress() {
        let wrapper = UserDefaultsWrapper()
        wrapper.remove(forKey: UserDefaultsWrapper.Key.legInfo.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.startLat.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.startLon.rawValue)
        wrapper.remove(forKey: UserDefaultsWrapper.Key.startAddress.rawValue)
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

// MARK: - Last Train
extension MainViewModel {
    //    func getRemainTimeInfo(info: LegInfo) {
    //        if let firstNonWalkMode = info.pathInfo.first(where: { $0.mode != .walk }) {
    //            print("최초의 walk 제외 mode: \(firstNonWalkMode.mode?.rawValue ?? "없음")")
    //
    //            switch firstNonWalkMode.mode {
    //            case .bus:
    //                let busDetailInfo = info.busInfo.filter { $0.routeName?.isEmpty == false }
    //                if let firstValidInfo = busDetailInfo.first(where: { $0.routeName != nil }) {
    //                    let request = BusRealTimeInfoRequest(
    //                        routeName: firstValidInfo.routeName,
    //                        stationName: firstValidInfo.start?.name,
    //                        lat: firstValidInfo.start?.lat,
    //                        lon: firstValidInfo.start?.lon,
    //                        passStations: firstValidInfo.passStations
    //                    )
    //                }
    //            case .subway:
    //                if let departureString = firstNonWalkMode.departureDateTime {
    //                    let formatter = DateFormatter()
    //                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    //                    formatter.timeZone = .current
    //
    //                    if let departureDate = formatter.date(from: departureString) {
    //                        let now = Date()
    //                        let interval = departureDate.timeIntervalSince(now) // 초 단위
    //
    //                        let minutes = Int(interval / 60)
    //                        let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
    //
    //                        //                        firstNonWalkMode.mode?.getIcon(for: firstNonWalkMode.type ?? "")
    //                        print("몇 호선 이야 : \(firstNonWalkMode.type)")
    //                        print("출발까지 남은 시간: \(minutes)분 \(seconds)초")
    //
    //
    //                    } else {
    //                        print("❌ 날짜 변환 실패: \(departureString)")
    //                    }
    //                }
    //            default: print("걷기만 해서 집에갈 수 있어!?")
    //            }
    //        }
    //    }
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
                destinationLat: UserDefaultsWrapper().double(forKey: UserDefaultsWrapper.Key.homeLat.rawValue),
                destinationLon: UserDefaultsWrapper().double(forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
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

//                  = LastTrainInfo(name: response.routeName,
//                                              time: response.realTimeBusArrival?.first?.remainingTime?.toHourMinuteSecondString,
//                                              icon: ,
//                                              remainingSeat: response.realTimeBusArrival?.first?.remainingStations)
//                print("버스 번호 : \(response.routeName)")
//                print("버스 남은 시간 : \(response.realTimeBusArrival?.first?.remainingTime?.toHourMinuteSecondString)")
//                print("버스 남은 좌석 : \(response.realTimeBusArrival?.first?.remainingStations)")
