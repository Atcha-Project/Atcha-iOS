//
//  TMapContainerView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/7/25.
//

import UIKit

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
    
    func deinitMapView() {
        tMapWrapper.mapView.vsmMapView?.viewWillDisappear()
    }
}
