//
//  TMapWrapper.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import UIKit
import TMapSDK
import CoreLocation
import VSMSDK

protocol MapRendering: AnyObject, TMapViewDelegate, TmapViewLocationDelegate {
    var mapView: TMapView { get }
}

protocol TMapWrapperDelegate: AnyObject {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D)
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D)
    func didFinishLoadingMap(_ mapView: TMapWrapper)
}

final class TMapWrapper: NSObject, MapRendering {
    private var userMarker: TMapMarker?
    var mapView: TMapView
    weak var delegate: TMapWrapperDelegate?
    
    public init(frame: CGRect) {
        self.mapView = TMapView(frame: UIScreen.main.bounds)
        super.init()
        configureDefaultSettings()
    }

    private func configureDefaultSettings() {
        mapView.setApiKey(Bundle.main.tMapKey)
        mapView.delegate = self
        mapView.locationDelgate = self
    }
    
    func updateUserMarker(coordinate: CLLocationCoordinate2D) {
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
    
    func addTrafficLine(passShape: String, color: UIColor) {
        let vertices = passShape.split(separator: " ").compactMap { pair -> VSMMapPoint? in
            let parts = pair.split(separator: ",")
            guard parts.count == 2,
                  let lon = Double(parts[0]),
                  let lat = Double(parts[1]) else { return nil }
            return VSMMapPoint(longitude: lon, latitude: lat)
        }

        guard vertices.count > 1 else {
            print("⚠️ 유효한 좌표가 부족합니다")
            return
        }

        let trafficLine = TrafficLine()
        trafficLine.vertices = vertices

        let tmapTrafficLine = TMapTrafficLine(trafficLine: [trafficLine])
        tmapTrafficLine.prevColor = color
        tmapTrafficLine.nextColor = color // ✅ 동일 색상 적용
        tmapTrafficLine.width = 6
        tmapTrafficLine.outlineWidth = 2
        tmapTrafficLine.showTrafficInfo = false // ✅ 강제 색상 사용 시 false로 설정
        tmapTrafficLine.showDirectionIndicator = true
        tmapTrafficLine.map = mapView
    }
}

extension TMapWrapper: TMapViewDelegate, TmapViewLocationDelegate {
    func mapViewDidFinishLoadingMap() {
        mapView.setMapType(.Night)
        mapView.setZoom(18)
//        mapView.isZoomEnable = false
        mapView.isShowCompass = false
        delegate?.didFinishLoadingMap(self)
    }

    func mapView(_ mapView: TMapView, singleTapOnMapWithoutTMapShape location: CLLocationCoordinate2D) {
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
