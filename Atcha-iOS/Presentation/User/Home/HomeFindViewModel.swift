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
    private let defaultCoord = CLLocationCoordinate2D(latitude: 37.56668000000002, longitude: 126.978433)
    var hasSavedLocation: Bool {
        locationStateHolder.currentLocation != nil
    }
    
    var onFinish: ((Bool) -> Void)?
    
    private let searchAddressUseCase: SearchAddressUseCase
    private let homePatchUseCase: HomePatchUseCase
    private let locationStateHolder: LocationStateHolder
    private let streamUseCase: ObserveLocationStreamUseCase
    private let signUpUseCase: SignUpUseCase
    private var tokenStorage: TokenStorage
    
    init(context: HomeRegisterContext,
         searchAddressUseCase: SearchAddressUseCase,
         homePatchUseCase: HomePatchUseCase,
         locationStateHolder: LocationStateHolder,
         streamUseCase: ObserveLocationStreamUseCase,
         signUpUseCase: SignUpUseCase,
         tokenStorage: TokenStorage) {
        
        self.context = context
        self.searchAddressUseCase = searchAddressUseCase
        self.homePatchUseCase = homePatchUseCase
        self.signUpUseCase = signUpUseCase
        self.locationStateHolder = locationStateHolder
        self.streamUseCase = streamUseCase
        self.tokenStorage = tokenStorage
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
        switch context {
        case .onboarding:
            saveCurrentLoaction()
            signUp()
        case .myPage, .home:
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
            
            let hasPresetText = (locationStateHolder.address?.isEmpty == false) ||
            (locationStateHolder.buildingName?.isEmpty == false)
            
            if !hasPresetText {
                Task { @MainActor in
                    await refreshAddress()
                }
            }
        } else {
            requestMyLocation()
        }
    }
    
    private func requestMyLocation() {
        Task { @MainActor in
            for await location in streamUseCase.startUpdate() {
                self.currentLocation = CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                await self.refreshAddress()
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
    
    @MainActor
    func applyDefaultLocationIfPermissionDenied() async {
        self.currentLocation = defaultCoord
        
        do {
            let addr = try await fetchCurrentAddress(
                lat: defaultCoord.latitude,
                lon: defaultCoord.longitude
            )
            self.address = addr?.address
            self.buildingName = addr?.name
        } catch {
            // 실패 시 최소 fallback(선택)
            self.address = "서울특별시 중구 세종대로"
            self.buildingName = "서울특별시청"
        }
    }
    
    @MainActor
    func refreshAddress() async {
        guard let loc = currentLocation else { return }
        do {
            let addr = try await fetchCurrentAddress(lat: loc.latitude, lon: loc.longitude)
            self.address = addr?.address
            self.buildingName = addr?.name
        } catch {
            print("주소 갱신 실패:", error)
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

// MARK: - SignUP
extension HomeFindViewModel {
    func signUp() {
        guard let provider = UserDefaultsWrapper.shared.integer(forKey: UserDefaultsWrapper.Key.provider.rawValue) else {
            print("플랫폼 정보 없음")
            return
        }
        
        guard let fcmToken = tokenStorage.fcmToken else {
            print("FCM 토큰이 없습니다.")
            return
        }
        
        let request = SignUpRequest(
            provider: provider,
            userName: "",
            address: locationStateHolder.address ?? "",
            lat: locationStateHolder.currentLocation?.latitude ?? 0.0,
            lon: locationStateHolder.currentLocation?.longitude ?? 0.0,
            alertFrequencies: [1, 10],
            fcmToken: fcmToken
        )
        
        // TODO: 위치 변경해야할 듯
        UserDefaultsWrapper.shared.set(locationStateHolder.currentLocation?.latitude ?? 0.0, forKey: UserDefaultsWrapper.Key.homeLat.rawValue)
        UserDefaultsWrapper.shared.set(locationStateHolder.currentLocation?.longitude ?? 0.0, forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
        
        Task {
            do {
                let response = try await signUpUseCase.excute(request)
                
                self.tokenStorage.accessToken = response.accessToken
                self.tokenStorage.refreshToken = response.refreshToken
                
                UserDefaultsWrapper.shared.set(response.id, forKey: UserDefaultsWrapper.Key.userId.rawValue)
                if let lat = response.lat, let lon = response.lon, let id = response.id {
                    UserDefaultsWrapper.shared.set(lat, forKey: UserDefaultsWrapper.Key.homeLat.rawValue)
                    UserDefaultsWrapper.shared.set(lon, forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
                    UserDefaultsWrapper.shared.set(id, forKey: UserDefaultsWrapper.Key.userId
                        .rawValue)
                    UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.reVisit
                        .rawValue)
                    
                    AmplitudeManager.shared.track(
                        .signup
                    )
                    print("회원가입 lat/lon 저장 완료: \(lat), \(lon)")
                    UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.isGuest.rawValue)
                } else {
                    print("회원가입 응답에 lat/lon 없음")
                }
                
                onFinish?(true)
            } catch {
                onFinish?(false)
            }
        }
    }
}
