//
//  MapViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation
import Combine

final class MapViewModel: BaseViewModel {
    @Published var currentLocation: CLLocation?
    var currentLocationSubject: PassthroughSubject<CLLocationCoordinate2D?, Never> = .init()
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private var streamTask: Task<Void, Never>?
    
    var goMyPage: (() -> Void)?
    
    init(authorizationUseCase: RequestLocationAuthorizationUseCase,
         streamUseCase: ObserveLocationStreamUseCase,
         searchAddressUseCase: SearchAddressUseCase) {
        self.authorizationUseCase = authorizationUseCase
        self.streamUseCase = streamUseCase
        self.searchAddressUseCase = searchAddressUseCase
    }
    
    func bindView() {
        currentLocationSubject
            .compactMap { $0 }
            .removeDuplicates()
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] coordinate in
                Task {
                    guard let self else { return }
                    let address = try? await self.fetchCurrentAddress(
                        lat: coordinate.latitude,
                        lon: coordinate.longitude
                    )
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
                    self.currentLocation = location
                }
            }
        }
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
extension MapViewModel {
    private func fetchCurrentAddress(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request: ReverseGeocodeLocationRequest = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await searchAddressUseCase.searchLocation(request)
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        abs(lhs.latitude - rhs.latitude) < 0.0001 &&
        abs(lhs.longitude - rhs.longitude) < 0.0001
    }
}
