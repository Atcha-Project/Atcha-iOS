//
//  MapViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import UIKit
import Foundation
import CoreLocation
import TMapSDK

final class MapViewController: BaseViewController<MapViewModel>, TMapWrapperDelegate {
    private let mapContainerView = TMapContainerView()
    private let lastTrainView: LastTrainSearchBottomView = LastTrainSearchBottomView()
    private let flagImageView: UIImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupAutoLayout()
        
        viewModel.bindView()
        viewModel.requestPermissionAndStartTracking()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //        tMapWrapper.mapView.vsmMapView?.viewWillDisappear()
    }
    
    private func setupUI() {
        mapContainerView.delegate = self
        
        view.addSubViews(flagImageView, lastTrainView, mapContainerView)
        
        flagImageView.image = UIImage.settingLocationMark
    }
    
    private func setupAutoLayout() {
        flagImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(65)
            make.width.equalTo(48)
        }
        mapContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.equalToSuperview()
        }
        
        lastTrainView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(256)
        }
    }
}

// MARK: - Delegate
extension MapViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {
        print("didUpdateLocation : \(coordinate.latitude)")
        print("didUpdateLocation : \(coordinate.longitude)")
    }
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {
        print("didUpdateLocation : \(coordinate.latitude)")
        print("didUpdateLocation : \(coordinate.longitude)")
    }
}
