//
//  CourseModifyViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/3/25.
//

import Foundation
import CoreLocation

final class CourseModifyViewModel: BaseViewModel {
    @Published private(set) var locations: [Location] = []
    private(set) var currentLocation: CLLocationCoordinate2D?
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let locationStateHolder: LocationStateHolder
    
    init(searchAddressUseCase: SearchAddressUseCase, authorizationUseCase: RequestLocationAuthorizationUseCase, locationStateHolder: LocationStateHolder) {
        self.searchAddressUseCase = searchAddressUseCase
        self.authorizationUseCase = authorizationUseCase
        self.locationStateHolder = locationStateHolder
        
        self.currentLocation = locationStateHolder.currentLocation
//        self.currentLocation = CLLocationCoordinate2D(latitude: 37.554722,
//                                                      longitude: 126.970833)
        
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

extension CourseModifyViewModel {
    func numberOfSections() -> Int {
        return locations.isEmpty ? 0 : 1
    }
    
    func selectedLocation(at indexPath: IndexPath) -> Location {
        return locations[indexPath.row]
    }
}
