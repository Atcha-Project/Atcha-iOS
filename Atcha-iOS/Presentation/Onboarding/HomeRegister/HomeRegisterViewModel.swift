//
//  HomeRegisterViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import Combine
import CoreLocation

enum HomeRegisterContext {
    case onboarding
    case myPage
}

enum LocationSelectionState {
    case none
    case selected(name: String, address: String)
}

final class HomeRegisterViewModel: BaseViewModel {
    @Published private(set) var context: HomeRegisterContext
    private var streamTask: Task<Void, Never>?
    
    private let requestUseCase: RequestLocationAuthorizationUseCase
    private let searchAddressUseCase: SearchAddressUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    var locationStateHolder: LocationStateHolder
    
    @Published var selectedState: LocationSelectionState?
    
    var routeHandler: ((HomeRouter) -> Void)?
    
    init(context: HomeRegisterContext,
         requestUseCase: RequestLocationAuthorizationUseCase,
         searchAddressUseCase: SearchAddressUseCase,
         streamUseCase: ObserveLocationStreamUseCase,
         locationStateHolder: LocationStateHolder) {
        self.context = context
        self.requestUseCase = requestUseCase
        self.searchAddressUseCase = searchAddressUseCase
        self.streamUseCase = streamUseCase
        self.locationStateHolder = locationStateHolder
        
        super.init()
        
        setupInitialState()
        self.bind()
    }
    
    private func setupInitialState() {
        let defaults = UserDefaultsWrapper.shared
        
        // 1. 이름과 주소가 이미 있다면 (직접 등록했던 유저) 바로 표시
        if let buildingName = defaults.string(forKey: UserDefaultsWrapper.Key.buildingName.rawValue),
           let address = defaults.string(forKey: UserDefaultsWrapper.Key.homeAddress.rawValue) {
            self.selectedState = .selected(name: buildingName, address: address)
            return
        }
        
        // 2. 이름은 없지만 좌표는 있다면 (방금 로그인한 유저)
        let lat = defaults.double(forKey: UserDefaultsWrapper.Key.homeLat.rawValue)
        let lon = defaults.double(forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
        
        if let lat, let lon, lat != 0.0 && lon != 0.0 {
            // 이름이 없으니 좌표로 이름을 새로 따와서 채워주기
            Task {
                if let location = try? await fetchCurrentAddress(lat: lat, lon: lon) {
                    let name = location.name ?? ""
                    let addr = location.address ?? ""
                    
                    // 따온 이름을 저장해두기 (다음엔 1번 조건에서 걸리도록)
                    defaults.set(name, forKey: UserDefaultsWrapper.Key.buildingName.rawValue)
                    defaults.set(addr, forKey: UserDefaultsWrapper.Key.homeAddress.rawValue)
                    
                    await MainActor.run {
                        self.selectedState = .selected(name: name, address: addr)
                    }
                }
            }
        } else {
            self.selectedState = LocationSelectionState.none
        }
    }
    
    func bind() {
        locationStateHolder.currentLocationSubject
            .compactMap { $0 }
            .handleEvents(receiveOutput: { [weak self] location in
                guard let self else { return }
                Task {
                    let address = try? await self.fetchCurrentAddress(
                        lat: location.latitude,
                        lon: location.longitude
                    )
                    
                    self.locationStateHolder.currentLocation = location
                    self.locationStateHolder.buildingName = address?.name
                    self.locationStateHolder.address = address?.address
                }
            })
            .sink { [weak self] location in
                guard let self else { return }
                if let name = self.locationStateHolder.buildingName,
                   let address = self.locationStateHolder.address {
                    selectedState = .selected(name: name, address: address)
                }
            }
            .store(in: &cancellables)
    }
    
    func requestMyLocation() {
        Task {
            streamTask = Task {
                for await location in streamUseCase.startUpdate() {
                    let currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    locationStateHolder.currentLocationSubject.send(currentLocation)
                    break
                }
            }
        }
    }
    
    
    func setupSelectedHome() {
        let name: String = locationStateHolder.buildingName ?? ""
        let address: String = locationStateHolder.address ?? ""
        self.selectedState = .selected(name: name, address: address)
    }
    
    private func fetchCurrentAddress(lat: Double, lon: Double) async throws -> Location? {
        let request: ReverseGeocodeLocationRequest = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await searchAddressUseCase.searchLocation(request)
    }
}

