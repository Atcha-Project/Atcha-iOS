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
    
    func updateUserMarker(location: CLLocationCoordinate2D) {
        tMapWrapper.updateUserMarker(coordinate: location)
    }
    
    func addTrafficLine(passShape: String) {
        tMapWrapper.addTrafficLine(passShape: passShape)
//        tMapWrapper.addWorkingTrafficLine()
    }
    
    func deinitMapView() {
        tMapWrapper.mapView.vsmMapView?.viewWillDisappear()
    }
}
