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
    
    // 온보딩 유즈케이스
    let onboardingUseCase: OnboardingUseCase
    
    // 검색된 장소 목록
    @Published private(set) var locations: [Location] = []
    
    init(onboardingUseCase: OnboardingUseCase) {
        self.onboardingUseCase = onboardingUseCase
    }
    
    // MARK: - 장소 검색
    @MainActor
    func searchLocation(keyword: String, lat: Double, lon: Double) {
        Task {
            do {
                let request = SearchLocationRequest(keyword: keyword, lat: lat, lon: lon)
                let response = try await onboardingUseCase.searchLocation(request)
                self.locations = response
            } catch {
                print("장소 검색 실패")
            }
        }
    }
    
    // MARK: - 좌표 -> 주소 변환
    func reverseGeocodeLocation(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await onboardingUseCase.reverseGeocodeLocation(request)
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
}
