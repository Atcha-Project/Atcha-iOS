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
    func mapViewDidStartScroll(_ mapView: TMapWrapper)
    func didFinishLoadingMap(_ mapView: TMapWrapper)
}

final class TMapWrapper: NSObject, MapRendering {
    private var userMarker: TMapMarker?
    var mapView: TMapView
    weak var delegate: TMapWrapperDelegate?
    
    private var trafficLines: [TMapTrafficLine] = []
    private var trafficMarkers: [TMapMarker] = []
    
    public init(frame: CGRect) {
        self.mapView = TMapView(frame: frame)
        super.init()
        configureDefaultSettings()
    }
    
    private func configureDefaultSettings() {
        mapView.setApiKey(AppConfig.tmapApiKey)
        mapView.delegate = self
        mapView.locationDelgate = self
    }
    
    func updateUserMarker(coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let marker = userMarker {
                marker.position = coordinate
                if marker.map == nil { marker.map = mapView } // ← 숨겨져 있던 마커 다시 보이게
            } else {
                userMarker = TMapMarker(position: coordinate)
                userMarker?.icon = UIImage.currentLocationMark
                userMarker?.map = mapView
            }
        }
    }
    
    func afterUserMarker() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let marker = self.userMarker else { return }
            marker.icon = UIImage.currentLocationMark
            
            if marker.map == nil { marker.map = self.mapView }
            else {
                marker.map = nil
                marker.map = self.mapView
            }
        }
    }
    
    /// 상태 전환: 이전(비활성/대기) 마커
    func beforeUserMarker() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let marker = self.userMarker else { return }
            marker.icon = UIImage.beforeCurrentLocation
            
            if marker.map == nil { marker.map = self.mapView }
            else {
                marker.map = nil
                marker.map = self.mapView
            }
        }
    }
    
    func addTrafficLine(
        passShape: String,
        color: UIColor,
        markerImage: UIImage? = nil,
        isFirst: Bool = false,
        isLast: Bool = false
    ) {
        // 1. 경로 문자열 파싱
        let vertices = passShape.split(separator: " ").compactMap { pair -> VSMMapPoint? in
            let parts = pair.split(separator: ",")
            guard parts.count == 2,
                  let lon = Double(parts[0]),
                  let lat = Double(parts[1]) else { return nil }
            return VSMMapPoint(longitude: lon, latitude: lat)
        }
        
        guard vertices.count > 1 else { return }
        
        // 2. 교통 라인 추가
        let trafficLine = TrafficLine()
        trafficLine.vertices = vertices
        
        let tmapTrafficLine = TMapTrafficLine(trafficLine: [trafficLine])
        tmapTrafficLine.prevColor = color
        tmapTrafficLine.nextColor = color
        tmapTrafficLine.width = 9
        tmapTrafficLine.outlineWidth = 0
        tmapTrafficLine.showTrafficInfo = false
        tmapTrafficLine.showDirectionIndicator = true
        tmapTrafficLine.map = mapView
        
        trafficLines.append(tmapTrafficLine)
        
        // 3. 시작 마커
        if isFirst, let start = vertices.first {
            let marker = TMapMarker(position: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude))
            marker.icon = UIImage.markerStart
            marker.map = mapView
            trafficMarkers.append(marker)
        }
        
        // 4. 도착 마커
        if isLast, let end = vertices.last {
            let marker = TMapMarker(position: CLLocationCoordinate2D(latitude: end.latitude, longitude: end.longitude))
            marker.icon = UIImage.markerEnd
            marker.map = mapView
            trafficMarkers.append(marker)
        }
        
        if let markerImage, let point = vertices.first {
            let marker = TMapMarker(position: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
            marker.icon = markerImage
            marker.offset = CGSize(width: 12, height: 12)
            marker.map = mapView
            trafficMarkers.append(marker)
        }
    }
    
    @MainActor
    func adjustMapToFit(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }
        mapView.fitMapBoundsWithPolygons([TMapPolygon(coordinates: coordinates)],
                                         inset: UIEdgeInsets(top: 110, left: 30, bottom: 160, right: 30))
    }
    
    func clearMap() {
        trafficLines.forEach { $0.map = nil }
        trafficLines.removeAll()
        
        trafficMarkers.forEach { $0.map = nil }
        trafficMarkers.removeAll()
    }
    
}

extension TMapWrapper: TMapViewDelegate, TmapViewLocationDelegate {
    func mapViewDidFinishLoadingMap() {
        mapView.setMapType(.Night)
        mapView.setZoom(16)
        mapView.isShowCompass = false
        mapView.isRotationEnable = true
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
        delegate?.mapViewDidStartScroll(self)
        delegate?.mapView(self, didUpdateLocation: newPosition)
    }
}

extension TMapWrapper {
    /// 현위치를 "routeInset 기준"으로 센터링하되, 화면에서 위로 50pt 올라가 보이게
    func centerUserWithRouteInset(_ location: CLLocationCoordinate2D, yOffsetUp points: CGFloat = 50) {
        let dLat = 0.00015
        let dLon = 0.00015

        let box = [
            CLLocationCoordinate2D(latitude: location.latitude - dLat, longitude: location.longitude - dLon),
            CLLocationCoordinate2D(latitude: location.latitude + dLat, longitude: location.longitude + dLon)
        ]

        // 기존 route inset 그대로 + bottom만 50 증가 = 화면에서 더 위로 보임
        let inset = UIEdgeInsets(top: 110, left: 30, bottom: 160 + points, right: 30)

        mapView.fitMapBoundsWithPolygons([TMapPolygon(coordinates: box)], inset: inset)
    }
}
