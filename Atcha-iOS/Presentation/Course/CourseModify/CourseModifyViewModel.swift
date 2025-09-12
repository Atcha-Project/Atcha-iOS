//
//  CourseModifyViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/3/25.
//

import Foundation
import CoreLocation

enum SearchResultItem {
    case recent(location: Location)
    case result(location: Location)
}

enum SearchResultSection: Int, CaseIterable {
    case region
    case place
    
    var title: String {
        switch self {
        case .region: return "주소 결과"
        case .place:  return "장소 결과"
        }
    }
}

enum SearchMode {
    case recent
    case result
}

final class CourseModifyViewModel: BaseViewModel {
    @Published private(set) var items: [SearchResultItem] = []
    @Published private(set) var sectionedItems: [[SearchResultItem]] = []
    private(set) var mode: SearchMode = .recent
    private(set) var isSectioned: Bool = false
    
    private(set) var currentLocation: CLLocationCoordinate2D?
    private(set) var initialLocation: Location?
    var onLocationSelected: ((Location) -> Void)?
    var onLocationConfirmed: ((LocationInfo, CLLocationCoordinate2D) -> Void)?
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let locationStateHolder: LocationStateHolder
    
    init(searchAddressUseCase: SearchAddressUseCase,
         authorizationUseCase: RequestLocationAuthorizationUseCase,
         locationStateHolder: LocationStateHolder,
         initialLocation: Location
    ) {
        self.searchAddressUseCase = searchAddressUseCase
        self.authorizationUseCase = authorizationUseCase
        self.locationStateHolder = locationStateHolder
        
        self.initialLocation = initialLocation
        self.currentLocation = CLLocationCoordinate2D(latitude: initialLocation.lat, longitude: initialLocation.lon)
        self.mode = .recent
        
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
    
    // MARK: - 최근 검색 장소
    @MainActor
    func recentSearchLocation() {
        Task {
            do {
                let request = FetchRecentSearchRequest(lat: currentLocation?.latitude, lon: currentLocation?.longitude)
                let response = try await searchAddressUseCase.fetchRecentSearchHistories(request)
                self.mode = .recent
                self.items = response.map { .recent(location: $0) }
            } catch {
                print("최근 장소 검색 실패")
            }
        }
    }
    
    // MARK: - 최근 검색 추가
    @MainActor
    func addRecentSearchLocation(request: RecentSearchRequest) {
        Task {
            do {
                let response = try await searchAddressUseCase.addRecentSearchHistory(request)
                print(response)
            } catch {
                print("최근 장소 추가 실패")
            }
        }
    }
    
    // MARK: - 최근 검색 전체 삭제
    @MainActor
    func clearAllSearchHistories() {
        Task {
            do {
                _ = try await searchAddressUseCase.clearAllSearchHistories()
                self.items = []
            } catch {
                print("최근 장소 전체 삭제 실패")
            }
        }
    }
    
    // MARK: - 최근 검색 삭제
    @MainActor
    func deleteSearchHistory(request: RecentSearchRequest) {
        Task {
            do {
                let _ = try await searchAddressUseCase.deleteSearchHistory(request)
                recentSearchLocation()
            } catch {
                print("최근 장소 삭제 실패")
            }
        }
    }
    
    // MARK: - 장소 검색
    @MainActor
    func searchLocation(keyword: String, lat: Double, lon: Double) {
        Task {
            do {
                let request = SearchLocationRequest(keyword: keyword, lat: lat, lon: lon)
                let response = try await searchAddressUseCase.searchAddress(request)
                self.mode = .result
                self.isSectioned = false
                self.items = response.map { .result(location: $0) }
                self.sectionedItems = []
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
        guard mode == .result else { return }
        
        let locs: [Location] = items.compactMap {
            if case let .result(loc) = $0 { return loc }
            return nil
        }
        
        let regionLocs = locs.filter { isRegionCategory($0.businessCategory) }
        let placeLocs  = locs.filter { !isRegionCategory($0.businessCategory) }
        
        let regionSection: [SearchResultItem] = regionLocs.map { .result(location: $0) }
        let placeSection:  [SearchResultItem] = placeLocs.map { .result(location: $0) }
        
        self.isSectioned = true
        self.sectionedItems = [regionSection, placeSection]
        self.items = (regionSection + placeSection)
    }
    
    func saveNewLocation(location: Location) {
        locationStateHolder.address = location.address
        locationStateHolder.buildingName = location.name
        locationStateHolder.currentLocation = CLLocationCoordinate2D(latitude: location.lat,
                                                                     longitude: location.lon)
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

extension CourseModifyViewModel {
    func selectedLocation(at indexPath: IndexPath) -> Location {
        switch items[indexPath.row] {
        case .recent(let loc), .result(let loc):
            return loc
        }
    }
    
    func numberOfSections() -> Int {
        if mode == .recent { return items.isEmpty ? 0 : 1 }
        return isSectioned ? SearchResultSection.allCases.count : (items.isEmpty ? 0 : 1)
    }
    
    func numberOfRows(in section: Int) -> Int {
        if mode == .recent { return items.count }
        return isSectioned ? sectionedItems[section].count : items.count
    }
    
    func item(at indexPath: IndexPath) -> SearchResultItem {
        if mode == .recent { return items[indexPath.row] }
        return isSectioned ? sectionedItems[indexPath.section][indexPath.row] : items[indexPath.row]
    }
    
    func titleForHeader(in section: Int) -> String? {
        guard mode == .result, isSectioned else { return nil }
        
        if sectionedItems[section].isEmpty {
            return nil
        }
        
        return SearchResultSection(rawValue: section)?.title
    }
}
