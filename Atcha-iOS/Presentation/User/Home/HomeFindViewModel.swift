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
    private(set) var context: HomeRegisterContext
    @Published var buildingName: String?
    @Published var address: String?
    @Published var currentLocation: CLLocationCoordinate2D?
    
    var routeHandler: ((HomeRouter) -> Void)?
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let locationStateHolder: LocationStateHolder
    
    init(context: HomeRegisterContext,
         searchAddressUseCase: SearchAddressUseCase,
         locationStateHolder: LocationStateHolder) {
        self.context = context
        self.searchAddressUseCase = searchAddressUseCase
        self.locationStateHolder = locationStateHolder
        self.buildingName = locationStateHolder.buildingName
        self.address = locationStateHolder.address
        
        super.init()
        self.bind()
    }
    
    private func bind() {
        $currentLocation
        //            .removeDuplicates()
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] location in
                guard let self, let location else { return }
                Task {
                    let address = try? await self.fetchCurrentAddress(lat: location.latitude,
                                                                      lon: location.longitude)
                    
                    self.address = address?.address
                    self.buildingName = address?.name
                }
            }
            .store(in: &cancellables)
    }
    
    func saveCurrentLoaction() {
        locationStateHolder.currentLocation = currentLocation
        locationStateHolder.buildingName = buildingName
        locationStateHolder.address = address
        locationStateHolder.currentLocationSubject.send(currentLocation)
    }
    
    func setupLocation() {
        currentLocation = locationStateHolder.currentLocation
    }
}

// MARK: - Search Address
extension HomeFindViewModel {
    private func fetchCurrentAddress(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request: ReverseGeocodeLocationRequest = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await searchAddressUseCase.searchLocation(request)
    }
}
