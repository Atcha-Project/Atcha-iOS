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
        
//        //임시 더미 데이터
//        let dummyRecents: [Location] = [
//            Location(name: "60계치킨 강남점", lat: 37.5013, lon: 127.0396, businessCategory: "치킨", address: "서울시 강남구 테헤란로 123", radius: "1.2km"),
//            Location(name: "스타벅스 역삼점", lat: 37.4999, lon: 127.0365, businessCategory: "카페", address: "서울시 강남구 역삼로 111", radius: "0.8km"),
//            Location(name: "이디야 선릉역점", lat: 37.5075, lon: 127.0481, businessCategory: "카페", address: "서울시 강남구 선릉로 88", radius: "1.0km")
//        ]
//        self.items = dummyRecents.map { .recent(location: $0) }
        self.mode = .recent
        
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
    func addRecentSearchLocation(request: AddRecentSearchRequest) {
        Task {
            do {
                print(request)
                _ = try await searchAddressUseCase.addRecentSearchHistory(request)
            } catch {
                print("최근 장소 추가 실패")
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
