//
//  MapViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import UIKit
import Foundation
import TMapSDK

final class MapViewController: BaseViewController<MapViewModel> {
    private let mapWrapper: MapRendering

    init(viewModel: MapViewModel,
         mapWrapper: MapRendering) {
        self.mapWrapper = mapWrapper
        super.init(viewModel: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(mapWrapper.mapView)
        
        mapWrapper.mapView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.equalToSuperview()
        }

        bindLocation()
        viewModel.requestPermissionAndStartTracking()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        mapWrapper.mapView.setMapType(.Night)
//        mapWrapper.mapView.setZoom(50)
    }

    private func bindLocation() {
//        viewModel.$currentLocation
//            .compactMap { $0 }
//            .scan((nil, nil)) { ($0.1, $1) }
//            .compactMap { previous, current in
//                guard let previous else { return current }
//                let distance = previous.distance(from: current)
//                return distance > 5 ? current : nil
//            }
//            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
//            .sink { [weak self] location in
//                self?.mapWrapper.setCenter(location.coordinate, animated: true)
//                self?.mapWrapper.addUserMarker(at: location.coordinate)
//            }
//            .store(in: &cancellables)
    }
}

extension MapViewController: TMapViewDelegate {
    func onDidFailedLoadingMap() {
//        mapWrapper.onDidLoadMap()
    }
}
