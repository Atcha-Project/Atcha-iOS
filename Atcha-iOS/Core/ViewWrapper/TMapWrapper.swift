//
//  TMapWrapper.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import UIKit
import TMapSDK
import CoreLocation

public protocol MapRendering {
    var mapView: TMapView { get }

    func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool)
    func addUserMarker(at coordinate: CLLocationCoordinate2D)
    func removeAllMarkers()
}

public final class TMapWrapper: MapRendering, TMapViewDelegate {
    public let mapView: TMapView

    public init(frame: CGRect) {
        self.mapView = TMapView(frame: frame)
        mapView.delegate = self
        configureDefaultSettings()
    }

    private func configureDefaultSettings() {
        mapView.setApiKey(Bundle.main.tMapKey)
        mapView.setMapType(.Night)
        mapView.setZoom(100)
    }

    public func setCenter(_ coordinate: CLLocationCoordinate2D,
                          animated: Bool = true) {
        mapView.setCenter(coordinate)
    }

    public func addUserMarker(at coordinate: CLLocationCoordinate2D) {
        let marker = TMapMarker(position: coordinate)
        marker.title = "현재 위치"
        marker.icon = UIImage.currentLocationMark

//        mapView.removeAllTMapMarkerItems()
//        mapView.addTMapMarkerItem(marker)
    }

    public func onDidLoadMap() {
        print("✅ 지도 로딩 완료됨, 다크모드 적용 중")
        mapView.setMapType(.Night)
    }
    
    public func removeAllMarkers() {
//        mapView
    }
}
