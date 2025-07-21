//
//  HomeRegisterViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import Combine
import CoreLocation

enum HomeRegisterContext {
    case onboarding
    case myPage
}

enum LocationSelectionState {
    case none
    case selected(name: String, address: String)
}

final class HomeRegisterViewModel: BaseViewModel {
    @Published private(set) var context: HomeRegisterContext
    private var streamTask: Task<Void, Never>?
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private let locationStateHolder: LocationStateHolder
    
    @Published var selectedState: LocationSelectionState?
    
    var routeHandler: ((HomeRouter) -> Void)?
    
    init(context: HomeRegisterContext,
         searchAddressUseCase: SearchAddressUseCase,
         streamUseCase: ObserveLocationStreamUseCase,
         locationStateHolder: LocationStateHolder) {
        self.context = context
        self.searchAddressUseCase = searchAddressUseCase
        self.streamUseCase = streamUseCase
        self.locationStateHolder = locationStateHolder
        
        super.init()
        self.bind()
    }
    
    func bind() {
        locationStateHolder.currentLocationSubject
            .compactMap { $0 }
            .handleEvents(receiveOutput: { [weak self] location in
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
            })
            .dropFirst()
            .sink { [weak self] location in
                guard let self else { return }
                if let name = self.locationStateHolder.buildingName,
                   let address = self.locationStateHolder.address {
                    selectedState = .selected(name: name, address: address)
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
    
    func setupSelectedHome() {
        let name: String = locationStateHolder.buildingName ?? ""
        let address: String = locationStateHolder.address ?? ""
        self.selectedState = .selected(name: name, address: address)
    }
    
    private func fetchCurrentAddress(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request: ReverseGeocodeLocationRequest = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await searchAddressUseCase.searchLocation(request)
    }
}

