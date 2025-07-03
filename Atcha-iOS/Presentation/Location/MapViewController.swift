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

protocol MapViewControllerDelegate: AnyObject {
    /// 맵 이동시 위치 좌표
    func mapViewController(_ controller: MapViewController,
                           didUpdateLocation coordinate: CLLocationCoordinate2D)

    /// 지도 탭으로 위치 선택 시 호출
    func mapViewController(_ controller: MapViewController,
                           didSelectLocation coordinate: CLLocationCoordinate2D)
}

final class MapViewController: BaseViewController<MapViewModel> {
    private var mapView: TMapView = TMapView()
    private var userMarker: TMapMarker?
    
    private let flagImageView: UIImageView = UIImageView()
    private let initialCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.62965537,
                                                                                   longitude: 127.04519683)
    weak var delegate: MapViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupAutoLayout()
        setupMapView()
        
        viewModel.requestPermissionAndStartTracking()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.vsmMapView?.viewWillDisappear()
    }
    
    private func setupMapView() {
        mapView.setApiKey(Bundle.main.tMapKey)
        mapView.delegate = self
        mapView.locationDelgate = self
        mapView.isShowCompass = false
        mapView.isTrackingLocation = true
        mapView.trackinMode = .followWithHeading
    }
    
    private func setupUI() {
        view.addSubViews(mapView, flagImageView)
        flagImageView.image = UIImage.settingLocationMark
    }
    
    private func setupAutoLayout() {
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        flagImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(65)
            make.width.equalTo(48)
        }
    }
    
    private func setupMarkerView() {
        userMarker = TMapMarker(position: initialCoordinate)
        userMarker?.icon = UIImage.currentLocationMark
        mapView.setCenter(initialCoordinate)
    }
}

// MARK: - Delegate
extension MapViewController: TMapViewDelegate, TmapViewLocationDelegate {
    func mapViewDidFinishLoadingMap() {
        mapView.setMapType(.Night)
        mapView.setZoom(30)
        setupMarkerView()
    }
    
    func mapView (_ mapView:TMapView,
                  singleTapOnMapWithoutTMapShape position: CLLocationCoordinate2D) {
        delegate?.mapViewController(self, didSelectLocation: position)
        mapView.setCenter(position)
    }
    
    func mapView(_ mapView: TMapView,
                 shouldChangeFrom oldPosition: CLLocationCoordinate2D,
                 to newPosition: CLLocationCoordinate2D) {
        guard let center = mapView.getCenter() else { return }
        delegate?.mapViewController(self, didUpdateLocation: center)
    }
    
    func didUpdateHeading(_ heading: CLHeading) {
        userMarker?.rotation  = Float(heading.trueHeading)
        userMarker?.map = mapView
    }
    
    func didUpdateLocation(_ location: CLLocationCoordinate2D) {
        userMarker?.position = location
        userMarker?.map = mapView
    }
}
