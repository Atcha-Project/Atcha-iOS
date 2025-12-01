//
//  LockViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/30/25.
//

import Combine
import Foundation

final class LockViewModel: BaseViewModel {
    @Published private(set) var taxiFare: Int
    var routerHandler: ((MainRoute) -> Void)?
    
    private var lockScreenWorkItem: DispatchWorkItem?
    private let fetchTaxiFareUseCase: FetchTaxiFareUseCase
    
    init(taxiFare: Int = 0,
         fetchTaxiFareUseCase: FetchTaxiFareUseCase) {
        self.taxiFare = taxiFare
        self.fetchTaxiFareUseCase = fetchTaxiFareUseCase
        super.init()
    }
    
    // MARK: - 택시 요금 업데이트
    func updateTaxiFare(to newFare: Int) {
        taxiFare = newFare
    }
    
    func refreshTaxiFare() {
        Task {
            do {
                let w = UserDefaultsWrapper.shared
                
                // 출발 좌표 (코스 등록할 때 저장해둔 값 사용)
                let startLatStr = w.string(forKey: UserDefaultsWrapper.Key.startLat.rawValue) ?? ""
                let startLonStr = w.string(forKey: UserDefaultsWrapper.Key.startLon.rawValue) ?? ""
                
                guard let startLat = Double(startLatStr),
                      let startLon = Double(startLonStr) else {
                    print("LockViewModel.refreshTaxiFare: 저장된 출발 좌표가 없음")
                    return
                }
                
                let homeLat = w.double(forKey: UserDefaultsWrapper.Key.homeLat.rawValue) ?? 0
                let homeLon = w.double(forKey: UserDefaultsWrapper.Key.homeLon.rawValue) ?? 0
                
                let request = FetchTaxiFareRequest(
                    originLat: startLat,
                    originLon: startLon,
                    destinationLat: homeLat,
                    destinationLon: homeLon
                )
                
                let fare = try await fetchTaxiFare(request: request)
                
                await MainActor.run {
                    self.taxiFare = Int(fare)
                }
            } catch {
                print("LockViewModel.refreshTaxiFare 실패: \(error)")
            }
        }
    }
    
    // MARK: - 타이머 취소
    func cancelLockScreenTimer() {
        lockScreenWorkItem?.cancel()
        lockScreenWorkItem = nil
    }
    
    private func executeAfterTwoMinutes() {
        routerHandler?(.lockScreen(info: nil, address: nil))
    }
    
    private func fetchTaxiFare(request: FetchTaxiFareRequest) async throws -> Double {
        return try await fetchTaxiFareUseCase.fetchTaxiFare(request: request)
    }
}
