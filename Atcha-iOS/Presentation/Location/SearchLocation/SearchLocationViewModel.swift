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
    @Published private(set) var sectionedItems: [[Location]] = []
    private(set) var isSectioned: Bool = false
    
    private(set) var currentLocation: CLLocationCoordinate2D?
    
    var routeHandler: ((HomeRouter) -> Void)?
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    var locationStateHolder: LocationStateHolder
    
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
            let status = await authorizationUseCase.askLocationPermission()
            print("status: \(status.rawValue)")
        }
    }
    
    // MARK: - 장소 검색
    @MainActor
    func searchLocation(keyword: String, lat: Double, lon: Double) {
        Task {
            do {
                self.isSectioned = false
                self.sectionedItems = []
                
                let request = SearchLocationRequest(keyword: keyword, lat: lat, lon: lon)
                let response = try await searchAddressUseCase.searchAddress(request)
                self.locations = response
            } catch {
                print("장소 검색 실패")
            }
        }
    }
    
    // MARK: - 지역 카테고리 판별
    private func isRegionCategory(_ category: String?) -> Bool {
        guard let c = category?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
        return c.contains("지역") || c == ","
    }
    
    // MARK: 지역 분리 테스트용
    @MainActor
    func prioritizeRegionInCurrentResults() {
        let locs: [Location] = locations
        
        let regionLocs = locs.filter { isRegionCategory($0.businessCategory) }
        let placeLocs  = locs.filter { !isRegionCategory($0.businessCategory) }
        
        self.isSectioned = true
        self.sectionedItems = [regionLocs, placeLocs]
        self.locations = (regionLocs + placeLocs)
    }
    
    func saveNewLocation(location: Location) {
        locationStateHolder.address = location.address
        locationStateHolder.buildingName = location.name
        locationStateHolder.currentLocation = CLLocationCoordinate2D(latitude: location.lat,
                                                                     longitude: location.lon)
        routeHandler?(.homeRegister(useDeviceLocation: false))
    }
    
    // MARK: - 서비즈 지역 확인
    @MainActor
    func checkServiceRegion(lat: Double, lon: Double) async -> Bool {
        let req = CheckServiceRegionRequest(lat: lat, lon: lon)
        do {
            let ok = try await searchAddressUseCase.checkServiceRegion(req)
            return ok
        } catch {
            print("서비스 지역 확인 실패:", error)
            return false
        }
    }
}

extension SearchLocationViewModel {
    func selectedLocation(at indexPath: IndexPath) -> Location {
        return locations[indexPath.row]
    }
    
    func numberOfSections() -> Int {
        return isSectioned ? SearchResultSection.allCases.count : (locations.isEmpty ? 0 : 1)
    }
    
    func numberOfRows(in section: Int) -> Int {
        return isSectioned ? sectionedItems[section].count : locations.count
    }
    
    func item(at indexPath: IndexPath) -> Location {
        return isSectioned ? sectionedItems[indexPath.section][indexPath.row]
        : locations[indexPath.row]
    }
    
    func titleForHeader(in section: Int) -> String? {
        guard isSectioned else { return nil }
        
        if sectionedItems[section].isEmpty {
            return nil
        }
        return SearchResultSection(rawValue: section)?.title
    }
}
