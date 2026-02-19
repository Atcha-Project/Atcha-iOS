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
            passStations: busDetailInfo.passStations
        )

        self.lastRequest = request

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.fetch(request: request, showLoading: true)
        }

        // 자동 새로고침: showLoading = false (silent)
        startAutoRefresh(request: request)
    }

    var icon: UIImage { busType.icon }

    @MainActor
    func fetch(request: BusRealTimeInfoRequest, showLoading: Bool){
        lastRequest = request

        currentTask?.cancel()

        if showLoading {
            setLoading(true)
        }

        currentTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if showLoading {
                    Task { @MainActor in self.setLoading(false) }
                }
            }

            do {
                let response = try await self.busInfoUseCase.busRealTimeInfo(request)
                await MainActor.run {
                    self.busRealTimeInfo = response
                    self.busRouteInfo = response.toBusRouteInfo()
                }

                guard let routeId = self.busRouteInfo.busRouteId, !routeId.isEmpty else {
                    await MainActor.run { self.isServerError = true }
                    return
                }

                let positionRequest = BusPositionInfoRequest(
                    busRouteId: self.busRouteInfo.busRouteId,
                    routeName: self.busRouteInfo.routeName,
                    serviceRegion: self.busRouteInfo.serviceRegion
                )

                try Task.checkCancellation()

                let position = try await self.busInfoUseCase.busPositionInfo(positionRequest)

                await MainActor.run {
                    self.isServerError = false
                    self.busPositionInfo = position
                }
            } catch is CancellationError {
                // ignore
            } catch {
                await MainActor.run {
                    self.isServerError = true
                }
            }
        }
    }

    // MARK: - 자동 새로고침
    private func startAutoRefresh(request: BusRealTimeInfoRequest) {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.fetch(request: request, showLoading: false)
            }
        }
        if let refreshTimer {
            RunLoop.main.add(refreshTimer, forMode: .common)
        }
    }

    // MARK: - 수동 새로고침
    @MainActor
    func refresh() {
        guard let request = lastRequest else { return }
        fetch(request: request, showLoading: false) // VC에서 showLoadingOnce로 처리할 거라 silent
    }

    deinit {
        refreshTimer?.invalidate()
        currentTask?.cancel()
    }

    func didTapInfo() {
        onInfoTap?(busRouteInfo)
    }
}
