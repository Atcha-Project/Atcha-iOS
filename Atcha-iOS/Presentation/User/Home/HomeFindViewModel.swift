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
  
    var currentLocationSubject = PassthroughSubject<CLLocationCoordinate2D?, Never>()
    private let searchAddressUseCase: SearchAddressUseCase
//    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    
    init(searchAddressUseCase: SearchAddressUseCase) {
        self.searchAddressUseCase = searchAddressUseCase
        super.init()
        
        self.bind()
    }
    
    private func bind() {
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
                    
                    self.address = address?.address
                    self.buildingName = address?.name
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Search Address
extension HomeFindViewModel {
    private func fetchCurrentAddress(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request: ReverseGeocodeLocationRequest = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await searchAddressUseCase.searchLocation(request)
    }
}
