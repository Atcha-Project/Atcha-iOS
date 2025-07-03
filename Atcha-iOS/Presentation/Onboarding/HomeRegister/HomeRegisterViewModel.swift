//
//  HomeRegisterViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import Combine
import CoreLocation

// 장소 상태 Enum
enum LocationSelectionState {
    case none
    case selected(name: String, address: String)
}

final class HomeRegisterViewModel: BaseViewModel {
    
    // 온보딩 유즈케이스
    let onboardingUseCase: OnboardingUseCase
    
    // 온보딩 콜백
    var onFinish: ((Bool) -> Void)?
    
    // 장소 선택/미선택 상태 변수
    @Published private(set) var locationState: LocationSelectionState = .none
    
    // 장소 정보 저장용
    var selectedLocation: SelectedLocation? = nil
    
    init(onboardingUseCase: OnboardingUseCase) {
        self.onboardingUseCase = onboardingUseCase
    }
    
    // MARK: - 현재 위치 전달
    func handleCurrentLocation(
        completion: @escaping (_ coordinate: CLLocationCoordinate2D,
                               _ placeName: String,
                               _ address: String) -> Void
    ) {
        onboardingUseCase.requestCurrentLocation { [weak self] coordinate in
            guard let self, let coordinate else { return }
            Task {
                do {
                    let response = try await self.reverseGeocodeLocation(
                        lat: coordinate.latitude,
                        lon: coordinate.longitude
                    )
                    
                    if let placeName = response.name, let address = response.address {
                        DispatchQueue.main.async {
                            completion(coordinate, placeName, address)
                        }
                    }
                    
                } catch {
                    print("❌ 장소 변환 실패: \(error)")
                }
            }
        }
    }
    
    // MARK: - 장소 업데이트
    func updateLocation(name: String, address: String, lat: Double, lon: Double) {
        self.selectedLocation = SelectedLocation(name: name, address: address, lat: lat, lon: lon)
        self.locationState = .selected(name: name, address: address)
    }
    
    // MARK: - 좌표 -> 주소 변환
    func reverseGeocodeLocation(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await onboardingUseCase.reverseGeocodeLocation(request)
    }
}
