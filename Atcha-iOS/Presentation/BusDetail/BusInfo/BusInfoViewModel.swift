//
//  BusInfoViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/29/25.
//

import Foundation
import UIKit

final class BusInfoViewModel: BaseViewModel {
    let busType: BusType
    let busNumber: String
    private let busInfoUseCase: BusInfoUseCase
    let busDetailInfo: BusDetailInfo
    let busRouteInfo: BusRouteInfo
    
    @Published var operationInfo: BusOperationInfo?
    
    init(
        busInfoUseCase: BusInfoUseCase,
        busDetailInfo: BusDetailInfo,
        busRouteInfo: BusRouteInfo
    ) {
        self.busInfoUseCase = busInfoUseCase
        
        guard let routeName = busDetailInfo.routeName else {
            fatalError("routeName is nil")
        }
        let split = routeName.splitRouteName()
        self.busType = BusType(from: split.type)
        self.busNumber = split.number
        self.busDetailInfo = busDetailInfo
        self.busRouteInfo = busRouteInfo
        super.init()
        
        let request = BusOperationInfoRequest(
            busRouteId: busRouteInfo.busRouteId,
            routeName: busRouteInfo.routeName,
            serviceRegion: busRouteInfo.serviceRegion)
        
        Task { [weak self] in
            await self?.busOperationInfo(request: request)
        }
    }
    
    var icon: UIImage {
        return busType.icon
    }
    
    // MARK: - 버스 운영 정보 조회
    @MainActor
    func busOperationInfo(request: BusOperationInfoRequest) {
        Task {
            do {
                let response = try await busInfoUseCase.busOperationInfo(request)
                self.operationInfo = response
            } catch {
                print("실시간 버스 조회 실패")
            }
        }
    }
}
