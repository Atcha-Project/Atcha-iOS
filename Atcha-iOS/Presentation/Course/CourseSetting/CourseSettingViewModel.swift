//
//  CourseSettingViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/18/25.
//

import Foundation
import CoreLocation

struct SettingAddress {
    var name: String?
    var address: String?
}

final class CourseSettingViewModel: BaseViewModel {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var address: SettingAddress
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private let locationStateHolder: LocationStateHolder
    private var streamTask: Task<Void, Never>?
    
    init(address: SettingAddress,
         authorizationUseCase: RequestLocationAuthorizationUseCase,
         streamUseCase: ObserveLocationStreamUseCase,
         searchAddressUseCase: SearchAddressUseCase,
         locationStateHolder: LocationStateHolder) {
        self.address = address
        self.authorizationUseCase = authorizationUseCase
        self.streamUseCase = streamUseCase
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
                guard let self, let location else { return }
                currentLocation = location
                Task {
                    let address = try? await self.fetchCurrentAddress(lat: location.latitude,
                                                                      lon: location.longitude)
                    
                    self.address.name = address?.name
                    self.address.address = address?.address
                }
            }
            .store(in: &cancellables)
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
extension CourseSettingViewModel {
    private func fetchCurrentAddress(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request: ReverseGeocodeLocationRequest = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await searchAddressUseCase.searchLocation(request)
    }
}
