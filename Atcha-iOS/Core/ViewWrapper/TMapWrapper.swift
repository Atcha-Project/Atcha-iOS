//
//  TMapWrapper.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import UIKit
import TMapSDK
import CoreLocation

public protocol MapRendering: AnyObject, TMapViewDelegate {
    var mapView: TMapView { get }

    func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool)
    func addUserMarker(at coordinate: CLLocationCoordinate2D)
    func removeAllMarkers()
}

final class TMapWrapper: NSObject, MapRendering, TMapViewDelegate {
    public let mapView: TMapView

    public init(frame: CGRect) {
        self.mapView = TMapView(frame: frame)
        super.init() // 반드시 호출
        mapView.delegate = self // ✅ delegate 연결
        configureDefaultSettings()
    }

    private func configureDefaultSettings() {
        mapView.setApiKey(Bundle.main.tMapKey)
        mapView.setZoom(100)
        // setMapType 은 onDidLoadMap 에서!
    }

    public func onDidLoadMap() {
        print("✅ 지도 로딩 완료 - 다크모드 적용")
        mapView.setMapType(.Night)
    }

    public func onDidFailedLoadingMap() {
        print("❌ 지도 로딩 실패")
    }
}

extension TMapWrapper {
    public func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool) {
        mapView.setCenter(coordinate)
    }
    
    public func addUserMarker(at coordinate: CLLocationCoordinate2D) {
        
    }
    
    public func removeAllMarkers() {
//        mapView.ma
    }
}
