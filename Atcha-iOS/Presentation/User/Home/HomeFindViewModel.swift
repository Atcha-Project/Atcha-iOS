//
//  HomeFindViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/8/25.
//

import Foundation
import Combine
import CoreLocation

final class HomeFindViewModel: BaseViewModel {
    @Published var buildingName: String?
    @Published var address: String?
    @Published var currentLocation: CLLocationCoordinate2D?
  
    var currentLocationSubject = PassthroughSubject<CLLocationCoordinate2D?, Never>()
    private let searchAddressUseCase: SearchAddressUseCase
    private let locationStateHolder: LocationStateHolder
    
    init(searchAddressUseCase: SearchAddressUseCase,
         locationStateHolder: LocationStateHolder) {
        self.searchAddressUseCase = searchAddressUseCase
        self.locationStateHolder = locationStateHolder
        self.buildingName = locationStateHolder.buildingName
        self.address = locationStateHolder.address
    }
    
    func finishLoadingMap() {
        currentLocation = locationStateHolder.currentLocation
    }
    
    func findCurrentLocation() {
        currentLocation = locationStateHolder.currentLocation
//        locationStateHolder.currentLocationSubject
//            .sink { [weak self] location in
//                self?.currentLocation = location
//            }
//            .store(in: &cancellables)
    }
}

// MARK: - Search Address
extension HomeFindViewModel {
    private func fetchCurrentAddress(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request: ReverseGeocodeLocationRequest = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await searchAddressUseCase.searchLocation(request)
    }
}
