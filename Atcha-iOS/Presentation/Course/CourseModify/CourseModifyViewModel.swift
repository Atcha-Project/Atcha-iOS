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

enum SearchMode {
    case recent
    case result
}

final class CourseModifyViewModel: BaseViewModel {
    @Published private(set) var items: [SearchResultItem] = []
    private(set) var mode: SearchMode = .recent
    private(set) var currentLocation: CLLocationCoordinate2D?
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let authorizationUseCase: RequestLocationAuthorizationUseCase
    private let locationStateHolder: LocationStateHolder
    
    init(searchAddressUseCase: SearchAddressUseCase, authorizationUseCase: RequestLocationAuthorizationUseCase, locationStateHolder: LocationStateHolder) {
        self.searchAddressUseCase = searchAddressUseCase
        self.authorizationUseCase = authorizationUseCase
        self.locationStateHolder = locationStateHolder
        
        //        self.currentLocation = locationStateHolder.currentLocation
        self.currentLocation = CLLocationCoordinate2D(latitude: 37.554722,
                                                      longitude: 126.970833)
        self.currentLocation = locationStateHolder.currentLocation
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
                self.items = self.items.filter {
                    switch $0 {
                    case .result: return false
                    case .recent: return false
                    }
                }
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
                let response = try await searchAddressUseCase.deleteSearchHistory(request)
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
                self.items = response.map { .result(location: $0) }
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
        return items.isEmpty ? 0 : 1
    }
    
    func selectedLocation(at indexPath: IndexPath) -> Location {
        switch items[indexPath.row] {
        case .recent(let loc), .result(let loc):
            return loc
        }
    }
}
