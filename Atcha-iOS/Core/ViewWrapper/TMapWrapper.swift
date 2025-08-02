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
    
    private var trafficLines: [TMapTrafficLine] = []
    private var trafficMarkers: [TMapMarker] = []
    
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
            marker.map = mapView
            trafficMarkers.append(marker)
        }

        // 5. 중간 마커
//        if !isFirst && !isLast, let start = vertices.first,
//           let image = markerImage?.withRenderingMode(.alwaysTemplate) {
//            let marker = TMapMarker(position: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude))
//            marker.icon = image.withTintColor(color)
//            marker.map = mapView
//            trafficMarkers.append(marker)
//        }
    }

    func adjustMapToFit(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }

        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }

        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }

        let rawCenterLat = (minLat + maxLat) / 2.0
        let centerLon = (minLon + maxLon) / 2.0

        let mapViewHeight = mapView.bounds.height * 0.55
        let screenHeight = UIScreen.main.bounds.height
        let mapRatio = mapViewHeight / screenHeight

        let desiredCenterRatioInMap = 0.5 / mapRatio
        let verticalOffsetRatio = 0.5 - desiredCenterRatioInMap

        let latSpan = maxLat - minLat
        let adjustedCenterLat = rawCenterLat + latSpan * verticalOffsetRatio

        let paddedLatSpan = latSpan + 0.01
        let paddedLonSpan = (maxLon - minLon) + 0.003

        let aspectRatio = mapView.bounds.width / mapView.bounds.height * 0.55
        let adjustedSpan = max(paddedLatSpan, paddedLonSpan * aspectRatio)

        let center = CLLocationCoordinate2D(latitude: adjustedCenterLat, longitude: centerLon)
        let zoomLevel = calculateZoomLevelBySpan(span: adjustedSpan)

        mapView.setCenter(center)
        mapView.setZoom(zoomLevel)
    }
    
    func calculateZoomLevelBySpan(span: Double) -> Int {
        switch span {
        case 0..<0.001: return 18
        case 0..<0.003: return 17
        case 0..<0.006: return 16
        case 0..<0.01:  return 15
        case 0..<0.02:  return 14
        case 0..<0.04:  return 13
        case 0..<0.07:  return 12
        case 0..<0.1:   return 11
        case 0..<0.2:   return 10
        case 0..<0.4:   return 9
        default:        return 8
        }
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
        mapView.setZoom(18)
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
