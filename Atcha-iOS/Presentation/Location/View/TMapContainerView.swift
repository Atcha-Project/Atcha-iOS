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
    var gestureTargetView: UIView { tMapWrapper.mapView }
    
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // SDK가 초기 frame 기반으로 렌더링 잡는 경우 대비
        tMapWrapper.mapView.frame = bounds
    }
    
    
    private func setupTMap() {
        tMapWrapper = TMapWrapper(frame: .zero)
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
        tMapWrapper.mapView.setZoom(16)
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
    
    func setHeading(_ heading: CLLocationDirection) {
        tMapWrapper.mapView.heading = heading
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

extension TMapContainerView {
    func setupCenterWithRouteInsetOffset(location: CLLocationCoordinate2D, points: CGFloat = 50) {
        tMapWrapper.centerUserWithRouteInset(location, yOffsetUp: points)
    }
}
