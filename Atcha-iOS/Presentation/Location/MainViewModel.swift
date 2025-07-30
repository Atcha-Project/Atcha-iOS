//
//  MainViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation
import Combine
import TMapSDK

final class MainViewModel: BaseViewModel {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var address: String?
    @Published var taxiFare: Double?
    @Published var legPathInfos: [LegPathInfo] = []
    @Published var legTrafficInfos: [LegTrafficInfo] = []
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let fetchTaxiFareUseCase: FetchTaxiFareUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private let locationStateHolder: LocationStateHolder
    private var streamTask: Task<Void, Never>?
    
    var routeHandler: ((MainRoute) -> Void)?
    var courseSearchResultHandler: ((LegInfo) -> Void)?
    
    init(authorizationUseCase: RequestLocationAuthorizationUseCase,
         streamUseCase: ObserveLocationStreamUseCase,
         fetchTaxiFareUseCase: FetchTaxiFareUseCase,
         searchAddressUseCase: SearchAddressUseCase,
         locationStateHolder: LocationStateHolder) {
        self.authorizationUseCase = authorizationUseCase
        self.streamUseCase = streamUseCase
        self.fetchTaxiFareUseCase = fetchTaxiFareUseCase
        self.searchAddressUseCase = searchAddressUseCase
        self.locationStateHolder = locationStateHolder
        
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
    
    func drawRoute(infos: LegInfo) {
        legPathInfos = infos.pathInfo
        legTrafficInfos = infos.trafficInfo
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
            routeHandler?(.detailRoute(infos: LegInfo(pathInfo: legPathInfos,
                                                      trafficInfo: legTrafficInfos)))
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

// MARK: - Bindigs
extension MainViewModel {
    private func handleLocationUpdate(_ location: CLLocationCoordinate2D?) {
        guard let location, legPathInfos.isEmpty else {
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
                destinationLat: UserDefaultsWrapper().double(forKey: UserDefaultsWrapper.Key.lat.rawValue),
                destinationLon: UserDefaultsWrapper().double(forKey: UserDefaultsWrapper.Key.lon.rawValue)
            )
            
            taxiFare = try? await fetchTaxiFare(request: request)
        } catch {
            print("❌ 주소 또는 요금 정보 업데이트 실패: \(error)")
        }
    }
}

// MARK: - Search Address
extension MainViewModel {
    private func fetchCurrentAddress(lat: Double, lon: Double) async throws -> Location? {
        let request: ReverseGeocodeLocationRequest = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await searchAddressUseCase.searchLocation(request)
    }
    
    private func fetchTaxiFare(request: FetchTaxiFareRequest) async throws -> Double {
        return try await fetchTaxiFareUseCase.fetchTaxiFare(request: request)
    }
}


//    func bindView() {
//        $currentLocation
//            .removeDuplicates()
//            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
//            .sink { [weak self] location in
//                guard let self, let location else { return }
//                currentLocation = location
//                Task {
//                    let info = try? await self.fetchCurrentAddress(lat: location.latitude,
//                                                                   lon: location.longitude)
//
//                    if let address = info?.name, !address.isEmpty {
//                        self.address = address
//                    } else if let address = info?.address {
//                        self.address = address
//                    }
//
//                    let request = FetchTaxiFareRequest(originLat: info?.lat,
//                                                       originLon: info?.lon,
//                                                       destinationLat: UserDefaultsWrapper().double(forKey: UserDefaultsWrapper.Key.lat.rawValue),
//                                                       destinationLon: UserDefaultsWrapper().double(forKey: UserDefaultsWrapper.Key.lon.rawValue))
//
//                    self.taxiFare = try? await self.fetchTaxiFare(request: request)
//                }
//
//            }
//            .store(in: &cancellables)
//    }
    
//    func bindView() {
//        $currentLocation
//            .removeDuplicates()
//            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
//            .sink { [weak self] location in
//                guard let self, let location else { return }
//
//                // ✅ 경로가 있을 경우 업데이트 중단
//                guard self.legPathInfos.isEmpty else {
//                    print("⛔️ 경로가 존재하므로 currentLocation 업데이트 중단")
//                    return
//                }
//
//                self.currentLocation = location
//
//                Task {
//                    do {
//                        let info = try await self.fetchCurrentAddress(lat: location.latitude, lon: location.longitude)
//
//                        if let name = info?.name, !name.isEmpty {
//                            self.address = name
//                        } else if let fallback = info?.address {
//                            self.address = fallback
//                        }
//
//                        let request = FetchTaxiFareRequest(
//                            originLat: info?.lat,
//                            originLon: info?.lon,
//                            destinationLat: UserDefaultsWrapper().double(forKey: UserDefaultsWrapper.Key.lat.rawValue),
//                            destinationLon: UserDefaultsWrapper().double(forKey: UserDefaultsWrapper.Key.lon.rawValue)
//                        )
//
//                        self.taxiFare = try? await self.fetchTaxiFare(request: request)
//
//                    } catch {
//                        print("❌ 주소 또는 택시요금 가져오기 실패: \(error)")
//                    }
//                }
//            }
//            .store(in: &cancellables)
//    }
