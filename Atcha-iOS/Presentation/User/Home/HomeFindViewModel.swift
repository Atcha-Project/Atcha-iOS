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
    private(set) var context: HomeRegisterContext
    @Published var buildingName: String?
    @Published var address: String?
    @Published var currentLocation: CLLocationCoordinate2D?
    var routeHandler: ((HomeRouter) -> Void)?
    var isInitialReqeust: Bool = false
    var forceDeviceLocation = false
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let homePatchUseCase: HomePatchUseCase
    private let locationStateHolder: LocationStateHolder
    private let streamUseCase: ObserveLocationStreamUseCase
    
    init(context: HomeRegisterContext,
         searchAddressUseCase: SearchAddressUseCase,
         homePatchUseCase: HomePatchUseCase,
         locationStateHolder: LocationStateHolder,
         streamUseCase: ObserveLocationStreamUseCase) {
        self.context = context
        self.searchAddressUseCase = searchAddressUseCase
        self.homePatchUseCase = homePatchUseCase
        self.locationStateHolder = locationStateHolder
        self.streamUseCase = streamUseCase
        self.buildingName = locationStateHolder.buildingName
        self.address = locationStateHolder.address
        
        super.init()
        self.bind()
    }
    
    private func bind() {
        $currentLocation
            .removeDuplicates()
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] location in
                guard let self, let location else { return }
                
                if isInitialReqeust {
                    Task {
                        let address = try? await self.fetchCurrentAddress(lat: location.latitude,
                                                                          lon: location.longitude)
                        
                        self.address = address?.address
                        self.buildingName = address?.name
                    }
                }
                
                isInitialReqeust = true
            }
            .store(in: &cancellables)
    }
    
    func handleRegister() {
        AmplitudeManager.shared.track(.home_register)
        
        switch context {
        case .onboarding:
            saveCurrentLoaction()
            
        case .myPage:
            guard let currentLocation,
                  let address else {
                print("집주소 변경 불가: 값 없음")
                return
            }
            
            let request = HomePatchRequest(
                address: address,
                lat: currentLocation.latitude,
                lon: currentLocation.longitude
            )
            
            Task { @MainActor in
                self.homePatch(request: request)
            }
        }
    }
    
    func saveCurrentLoaction() {
        locationStateHolder.currentLocation = currentLocation
        locationStateHolder.buildingName = buildingName
        locationStateHolder.address = address
        locationStateHolder.currentLocationSubject.send(currentLocation)
    }
    
    func setupLocation() {
        if forceDeviceLocation {
            requestMyLocation()
            forceDeviceLocation = false
            isInitialReqeust = true
            return
        }
        if let saved = locationStateHolder.currentLocation {
            currentLocation = saved
        } else {
            requestMyLocation()
        }
//
//        if let savedLocation = locationStateHolder.currentLocation {
//            currentLocation = savedLocation
//        } else {
//            requestMyLocation()
//        }
    }
    
    private func requestMyLocation() {
        Task {
            for await location in streamUseCase.startUpdate() {
                self.currentLocation = CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                break
            }
        }
    }
    
    // MARK: - 집주소 번경
    @MainActor
    func homePatch(request: HomePatchRequest) {
        Task {
            do {
                let response = try await homePatchUseCase.homePatch(request)
                
                if let lat = response.lat {
                    UserDefaultsWrapper.shared.set(lat, forKey: UserDefaultsWrapper.Key.homeLat.rawValue)
                }
                if let lon = response.lon {
                    UserDefaultsWrapper.shared.set(lon, forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
                }
                if let addr = response.address {
                    UserDefaultsWrapper.shared.set(addr, forKey: UserDefaultsWrapper.Key.homeAddress.rawValue)
                }
                UserDefaultsWrapper.shared.set(self.buildingName, forKey: UserDefaultsWrapper.Key.buildingName.rawValue)
                
                if let lat = response.lat,
                   let lon = response.lon {
                    let newLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    
                    locationStateHolder.currentLocation = newLocation
                    locationStateHolder.buildingName = self.buildingName
                    locationStateHolder.address = self.address
                    locationStateHolder.currentLocationSubject.send(newLocation)
                }
            } catch {
                print("집주소 변경 실패: \(error)")
            }
        }
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

// MARK: - Search Address
extension HomeFindViewModel {
    private func fetchCurrentAddress(lat: Double, lon: Double) async throws -> Location? {
        let request: ReverseGeocodeLocationRequest = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await searchAddressUseCase.searchLocation(request)
    }
}
