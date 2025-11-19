//
//  TMapContainerView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/7/25.
//

import UIKit
import CoreLocation
import TMapSDK
import SnapKit

final class TMapContainerView: UIView {
    private var tMapWrapper: TMapWrapper!
    
    weak var delegate: TMapWrapperDelegate? {
        didSet {
            tMapWrapper?.delegate = delegate
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTMap()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTMap()
    }
    
    private func setupTMap() {
        tMapWrapper = TMapWrapper(frame: bounds)
        tMapWrapper.delegate = delegate
        addSubview(tMapWrapper.mapView)
        tMapWrapper.mapView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func setupCenter(location: CLLocationCoordinate2D) {
        tMapWrapper.mapView.setCenter(location)
    }
    
    func setupZoomCenter(location: CLLocationCoordinate2D) {
        tMapWrapper.mapView.setCenter(location)
        tMapWrapper.mapView.setZoom(18)
    }
    
    func updateUserMarker(location: CLLocationCoordinate2D) {
        tMapWrapper.updateUserMarker(coordinate: location)
    }
    
    func afterUserMarker() { tMapWrapper.afterUserMarker() }
    func beforeUserMarker() { tMapWrapper.beforeUserMarker() }
    
    func addTrafficLine(passShape: String, color: UIColor, markerImage: UIImage? = nil, isFirst: Bool = false, isLast: Bool = false) {
        tMapWrapper.addTrafficLine(passShape: passShape, color: color, markerImage: markerImage, isFirst: isFirst, isLast: isLast)
    }
    
    func adjustMapToFit(coordinates: [CLLocationCoordinate2D]) {
        tMapWrapper.adjustMapToFit(coordinates: coordinates)
    }
    
    func clearMapView() {
        tMapWrapper.clearMap()
    }
    
    func deinitMapView() {
        tMapWrapper.mapView.vsmMapView?.viewWillDisappear()
    }
}

extension TMapContainerView {
    func reloadMapView() {
        tMapWrapper.mapView.removeFromSuperview()
        tMapWrapper = nil

        // 다시 생성
        setupTMap()
    }
}
