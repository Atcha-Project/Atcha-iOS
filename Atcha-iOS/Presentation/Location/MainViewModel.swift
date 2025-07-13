//
//  MainViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation
import Combine

final class MainViewModel: BaseViewModel {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var address: String?
    @Published var taxiFare: Double?
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let fetchTaxiFareUseCase: FetchTaxiFareUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private var streamTask: Task<Void, Never>?
    
    var routeHandler: ((MainRoute) -> Void)?
    
    init(authorizationUseCase: RequestLocationAuthorizationUseCase,
         streamUseCase: ObserveLocationStreamUseCase,
         fetchTaxiFareUseCase: FetchTaxiFareUseCase,
         searchAddressUseCase: SearchAddressUseCase) {
        self.authorizationUseCase = authorizationUseCase
        self.streamUseCase = streamUseCase
        self.fetchTaxiFareUseCase = fetchTaxiFareUseCase
        self.searchAddressUseCase = searchAddressUseCase
        
        super.init()
        self.bindView()
    }
    
    func bindView() {
        $currentLocation
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] location in
                guard let self, let location else { return }
                Task {
                    let address = try? await self.fetchCurrentAddress(lat: location.latitude,
                                                                      lon: location.longitude)
                    
                    if let name = address?.name {
                        self.address = name
                    } else if let address = address?.address {
                        self.address = address
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func requestPermissionAndStartTracking() {
        Task {
            let status = await authorizationUseCase.askPermission()
            guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
            
            streamTask = Task {
                for await location in streamUseCase.startUpdate() {
                    let currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    self.currentLocation = currentLocation
                    break
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

// MARK: - Search Address
extension MainViewModel {
    private func fetchCurrentAddress(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request: ReverseGeocodeLocationRequest = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await searchAddressUseCase.searchLocation(request)
    }
}

//extension CLLocationCoordinate2D: Equatable {
//    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
//        abs(lhs.latitude - rhs.latitude) < 0.0001 &&
//        abs(lhs.longitude - rhs.longitude) < 0.0001
//    }
//}

//        $currentLocation
//            .compactMap { $0 }
//            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
//            .sink { [weak self] coordinate in
//                Task {
//                    guard let self else { return }
//                    let address = try? await self.fetchCurrentAddress(
//                        lat: coordinate.latitude,
//                        lon: coordinate.longitude
//                    )
//
//                    self.address = address?.name
//
//                    let request = FetchTaxiFareRequest(originLat: address?.lat,
//                                                       originLon: address?.lon,
//                                                       destinationLat: 37.58746906188554,
//                                                       destinationLon: 126.9855465633904)
//
//                    self.taxiFare = try? await self.fetchTaxiFareUseCase.fetchTaxiFare(request: request)
//                }
//            }
//            .store(in: &cancellables)
        
