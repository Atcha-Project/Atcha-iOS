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
    private var lastRequest: BusOperationInfoRequest?
    private var currentTask: Task<Void, Never>?
    
    @Published var operationInfo: BusOperationInfo?
    @Published var isServerError: Bool = false
    
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
        guard let busRouteId = request.busRouteId, !busRouteId.isEmpty,
              let routeName = request.routeName, !routeName.isEmpty,
              let serviceRegion = request.serviceRegion, !serviceRegion.isEmpty else {
            self.isServerError = true
            return
        }

        lastRequest = request
        currentTask?.cancel()
        
        Task {
            do {
                let response = try await busInfoUseCase.busOperationInfo(request)

                guard let stationName = response.startStationName, !stationName.isEmpty else {
                    isServerError = true
                    return
                }
                self.isServerError = false
                self.operationInfo = response

            } catch {
                self.isServerError = true
                print("버스 운영 정보 조회 실패: \(error)")
            }
        }
    }
    
    // MARK: - 수동 새로고침
    @MainActor
    func refresh() {
        guard let request = lastRequest else { return }
        Task {
            self.busOperationInfo(request: request)
        }
    }
}
