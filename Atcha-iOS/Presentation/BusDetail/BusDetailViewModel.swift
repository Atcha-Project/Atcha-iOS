//
//  BusDetailViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/29/25.
//

import Foundation
import UIKit

struct BusRouteInfo {
    let busRouteId: String?
    let routeName: String?
    let serviceRegion: String?
}

final class BusDetailViewModel: BaseViewModel {
    let busType: BusType
    let busNumber: String
    let busDetailInfo: BusDetailInfo
    private let busInfoUseCase: BusInfoUseCase
    var busRouteInfo = BusRouteInfo(busRouteId: "", routeName: "", serviceRegion: "")
    var onInfoTap: ((BusRouteInfo) -> Void)?
    
    @Published var busPositionInfo: BusPositionInfo?
    @Published var busRealTimeInfo: BusRealTimeInfo?
    @Published var isServerError: Bool = false
    
    private var refreshTimer: Timer?
    private var lastRequest: BusRealTimeInfoRequest?
    private var didInitialLoad = false
    private var currentTask: Task<Void, Never>?
    
    
    init(
        busInfoUseCase: BusInfoUseCase,
        busDetailInfo: BusDetailInfo
    ) {
        self.busInfoUseCase = busInfoUseCase
        
        guard let routeName = busDetailInfo.routeName else {
            fatalError("routeName is nil")
        }
        let split = routeName.splitRouteName()
        self.busType = BusType(from: split.type)
        self.busNumber = split.number
        self.busDetailInfo = busDetailInfo
        super.init()
        
        let request = BusRealTimeInfoRequest(
            routeName: busDetailInfo.routeName,
            stationName: busDetailInfo.start?.name,
            lat: busDetailInfo.start?.lat,
            lon: busDetailInfo.start?.lon,
            passStations: busDetailInfo.passStations)
        
        Task { [weak self] in
            await self?.busRealTimeInfo(request: request)
        }
        
        startAutoRefresh(request: request)
    }
    
    var icon: UIImage {
        return busType.icon
    }
    
    // MARK: - 실시간 버스 정보 조회
    @MainActor
    func busRealTimeInfo(request: BusRealTimeInfoRequest) {
        lastRequest = request
        
        cancelInFlight()
        
        let shouldShowLoading = !didInitialLoad
        if shouldShowLoading {
            didInitialLoad = true
            setLoading(true)
        }
        
        defer { if shouldShowLoading { setLoading(false) } }
        
        Task {
            do {
                let response = try await busInfoUseCase.busRealTimeInfo(request)
                self.busRouteInfo = response.toBusRouteInfo()
                
                guard let routeId = busRouteInfo.busRouteId, !routeId.isEmpty else {
                    self.isServerError = true
                    return
                }
                
                self.isServerError = false
                
                let positionRequest = BusPositionInfoRequest(
                    busRouteId: busRouteInfo.busRouteId,
                    routeName: busRouteInfo.routeName,
                    serviceRegion: busRouteInfo.serviceRegion
                )
                
                try Task.checkCancellation()
                
                let position = try await busInfoUseCase.busPositionInfo(positionRequest)
                self.busPositionInfo = position
            } catch {
                self.isServerError = true
                print("실시간 버스 조회 실패")
            }
        }
    }
    
    // MARK: - 버스 위치 정보 조회
    @MainActor
    func busPositionInfo(request: BusPositionInfoRequest) {
        Task {
            do {
                let response = try await busInfoUseCase.busPositionInfo(request)
                self.isServerError = false
                self.busPositionInfo = response
            } catch {
                self.isServerError = true
                print("버스 위치 정보 실패")
            }
        }
    }
    
    // MARK: - 자동 새로고침
    private func startAutoRefresh(request: BusRealTimeInfoRequest) {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.busRealTimeInfo(request: request)
            }
        }
        RunLoop.main.add(refreshTimer!, forMode: .common)
    }
    
    
    // MARK: - 수동 새로고침
    @MainActor
    func refresh() {
        guard let request = lastRequest else { return }
        Task {
            self.busRealTimeInfo(request: request)
        }
    }
    
    
    @MainActor
    private func cancelInFlight() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    func didTapInfo() {
        onInfoTap?(busRouteInfo)
    }
}
