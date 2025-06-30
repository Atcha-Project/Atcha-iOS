//
//  RegisterLocationViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/26/25.
//

import Foundation
import CoreLocation

final class RegisterLocationViewModel: BaseViewModel {
    let onboardingUseCase: OnboardingUseCase
    
    // 현재 선택된 위치 상태
    @Published private(set) var currentCoordinate: CLLocationCoordinate2D?
    @Published private(set) var placeName: String?
    @Published private(set) var address: String?
    
    init(onboardingUseCase: OnboardingUseCase) {
        self.onboardingUseCase = onboardingUseCase
    }
    
    // MARK: - 현재 주소 변환
    func updateCurrentLocation() {
        onboardingUseCase.requestCurrentLocation { [weak self] coordinate in
            guard let self, let coordinate = coordinate else { return }
            Task {
                do {
                    let geo = try await self.reverseGeocodeLocation(lat: coordinate.latitude, lon: coordinate.longitude)
                    
                    DispatchQueue.main.async {
                        self.currentCoordinate = coordinate
                        self.placeName = geo.name
                        self.address = geo.address
                    }
                } catch {
                    print("❌ reverseGeocode 실패: \(error)")
                }
            }
        }
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
                    let placeName = response.name
                    let address = response.address
                    
                    DispatchQueue.main.async {
                        completion(coordinate, placeName, address)
                    }
                } catch {
                    print("❌ 장소 변환 실패: \(error)")
                }
            }
        }
    }
    
    // MARK: - 위치 이동시 주소 반환
    func updateLocationByMapMovement(lat: Double, lon: Double) {
        Task {
            do {
                let geo = try await self.reverseGeocodeLocation(lat: lat, lon: lon)
                
                DispatchQueue.main.async {
                    self.currentCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    self.placeName = geo.name
                    self.address = geo.address
                }
            } catch {
                print("❌ reverseGeocode 실패: \(error)")
            }
        }
    }
    
    // MARK: - 좌표 -> 주소 변환
    func reverseGeocodeLocation(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await onboardingUseCase.reverseGeocodeLocation(request)
    }
}
