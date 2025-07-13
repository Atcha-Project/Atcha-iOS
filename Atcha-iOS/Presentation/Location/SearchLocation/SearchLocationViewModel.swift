//
//  SearchLocationViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import Foundation
import Combine
import CoreLocation

final class SearchLocationViewModel: BaseViewModel {
    @Published private(set) var locations: [Location] = []
    private(set) var currentLocation: CLLocationCoordinate2D?
    
    var routeHandler: ((OnboardingRoute) -> Void)?
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let locationStateHolder: LocationStateHolder
    
    init(searchAddressUseCase: SearchAddressUseCase,
         authorizationUseCase: RequestLocationAuthorizationUseCase,
         locationStateHolder: LocationStateHolder) {
        self.searchAddressUseCase = searchAddressUseCase
        self.authorizationUseCase = authorizationUseCase
        self.locationStateHolder = locationStateHolder
        
        self.currentLocation = locationStateHolder.currentLocation
        
        super.init()
        self.requestPermission()
    }
    
    // MARK: - 권한 요청
    func requestPermission() {
        Task {
            let status = await authorizationUseCase.askPermission()
            print("status: \(status.rawValue)")
        }
    }
    
    // MARK: - 장소 검색
    @MainActor
    func searchLocation(keyword: String, lat: Double, lon: Double) {
        Task {
            do {
                let request = SearchLocationRequest(keyword: keyword, lat: lat, lon: lon)
                let response = try await searchAddressUseCase.searchAddress(request)
                self.locations = response
            } catch {
                print("장소 검색 실패")
            }
        }
    }
    
    func saveNewLocation(location: Location) {
        locationStateHolder.address = location.address
        locationStateHolder.buildingName = location.name
        locationStateHolder.currentLocation = CLLocationCoordinate2D(latitude: location.lat,
                                                                     longitude: location.lon)
    }
}

extension SearchLocationViewModel {
    func numberOfSections() -> Int {
        return locations.isEmpty ? 0 : 1
    }
    
    func selectedLocation(at indexPath: IndexPath) -> Location {
        return locations[indexPath.row]
    }
}


// MARK: - 좌표 -> 주소 변환
//    func reverseGeocodeLocation(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
//        let request = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
//        return try await onboardingUseCase.reverseGeocodeLocation(request)
//    }

// MARK: - 현재 위치 전달
//    func handleCurrentLocation(
//        completion: @escaping (_ coordinate: CLLocationCoordinate2D,
//                               _ placeName: String,
//                               _ address: String) -> Void
//    ) {
//        onboardingUseCase.requestCurrentLocation { [weak self] coordinate in
//            guard let self, let coordinate else { return }
//            Task {
//                do {
//                    let response = try await self.reverseGeocodeLocation(
//                        lat: coordinate.latitude,
//                        lon: coordinate.longitude
//                    )
//
//                    if let placeName = response.name, let address = response.address {
//                        DispatchQueue.main.async {
//                            completion(coordinate, placeName, address)
//                        }
//                    }
//
//                } catch {
//                    print("❌ 장소 변환 실패: \(error)")
//                }
//            }
//        }
//    }
