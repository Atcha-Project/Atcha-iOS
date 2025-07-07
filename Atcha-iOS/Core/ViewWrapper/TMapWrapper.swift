//
//  TMapWrapper.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import UIKit
import TMapSDK
import CoreLocation

protocol MapRendering: AnyObject, TMapViewDelegate, TmapViewLocationDelegate {
    var mapView: TMapView { get }
}

protocol TMapWrapperDelegate: AnyObject {
    func mapView(_ mapView: TMapWrapper,
                 didUpdateLocation coordinate: CLLocationCoordinate2D)
    
    func mapView(_ mapView: TMapWrapper,
                 didSelectLocation coordinate: CLLocationCoordinate2D)
}

final class TMapWrapper: NSObject, MapRendering {
    private var userMarker: TMapMarker?
    let mapView: TMapView
    
    weak var delegate: TMapWrapperDelegate?
    
    public init(frame: CGRect) {
        self.mapView = TMapView(frame: frame)
        super.init()
        
        configureDefaultSettings()
    }

    private func configureDefaultSettings() {
        mapView.setApiKey(Bundle.main.tMapKey)
        mapView.delegate = self
        mapView.locationDelgate = self
        mapView.isShowCompass = false
        mapView.isTrackingLocation = true
        mapView.trackinMode = .followWithHeading
        mapView.setZoom(20)
    }
    
    private func updateUserMarker(coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let marker = userMarker {
                marker.position = coordinate
            } else {
                userMarker = TMapMarker(position: coordinate)
                userMarker?.icon = UIImage.currentLocationMark
                userMarker?.map = mapView
            }
        }
    }
}

extension TMapWrapper: TMapViewDelegate, TmapViewLocationDelegate {
    func mapViewDidFinishLoadingMap() {
        mapView.setMapType(.Night)
        mapView.setZoom(20)
        
        guard let center = mapView.getCenter() else { return }
        updateUserMarker(coordinate: center)
    }
    
    func mapView(_ mapView: TMapView,
                 singleTapOnMapWithoutTMapShape location: CLLocationCoordinate2D) {
        delegate?.mapView(self, didSelectLocation: location)
        mapView.setCenter(location)
    }
    
    func mapView(_ mapView: TMapView, singleTapOnMap location: CLLocationCoordinate2D) {
        delegate?.mapView(self, didSelectLocation: location)
        mapView.setCenter(location)
    }
    
    func mapView(_ mapView: TMapView,
                 shouldChangeFrom oldPosition: CLLocationCoordinate2D,
                 to newPosition: CLLocationCoordinate2D) {
        delegate?.mapView(self, didUpdateLocation: newPosition)
    }
}
