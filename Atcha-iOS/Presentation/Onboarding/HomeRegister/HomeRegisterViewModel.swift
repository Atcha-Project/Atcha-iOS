//
//  HomeRegisterViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import Combine
import CoreLocation

final class HomeRegisterViewModel: BaseViewModel {
    var findLocationSubeject = PassthroughSubject<Void, Never>()
    var searchAddressSubject = PassthroughSubject<Void, Never>()
    
    private var streamTask: Task<Void, Never>?
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private let locationStateHolder: LocationStateHolder

    init(searchAddressUseCase: SearchAddressUseCase,
         streamUseCase: ObserveLocationStreamUseCase,
         locationStateHolder: LocationStateHolder) {
        self.searchAddressUseCase = searchAddressUseCase
        self.streamUseCase = streamUseCase
        self.locationStateHolder = locationStateHolder
        
        super.init()
        self.requestMyLocation()
        self.bind()
    }
    
    func bind() {
        locationStateHolder.currentLocationSubject
            .removeDuplicates()
            .sink { [weak self] location in
                guard let self else { return }
                Task {
                    let address = try? await self.fetchCurrentAddress(
                        lat: location.latitude,
                        lon: location.longitude
                    )
                    
                    self.locationStateHolder.currentLocation = location
                    self.locationStateHolder.buildingName = address?.name
                    self.locationStateHolder.address = address?.address
                }
            }
            .store(in: &cancellables)
    }
    
    func requestMyLocation() {
        Task {
//            let status = await authorizationUseCase.askPermission()
//            guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
            streamTask = Task {
                for await location in streamUseCase.startUpdate() {
                    let currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    locationStateHolder.currentLocationSubject.send(currentLocation)
                    break
                }
            }
        }
    }
    
    func findLocationTapped() {
        findLocationSubeject.send(())
    }
    
    func searchAddressTapped() {
        searchAddressSubject.send(())
    }
    
    private func fetchCurrentAddress(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request: ReverseGeocodeLocationRequest = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await searchAddressUseCase.searchLocation(request)
    }
}

// 장소 상태 Enum
enum LocationSelectionState {
    case none
    case selected(name: String, address: String)
}
