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

    func addTrafficLine(passShape: String) {
        let vertices = passShape.split(separator: " ").compactMap { pair -> VSMMapPoint? in
            let parts = pair.split(separator: ",")
            guard parts.count == 2,
                  let lon = Double(parts[0]),
                  let lat = Double(parts[1]) else { return nil }
            return VSMMapPoint(longitude: lon, latitude: lat)
        }
        
        let trafficLine = TrafficLine()
        trafficLine.vertices = (vertices as NSArray) as! [VSMMapPoint] // NSArray로 변환

        let tmapTrafficLine = TMapTrafficLine(trafficLine: [trafficLine])
        tmapTrafficLine.nextColor = .blue
        tmapTrafficLine.prevColor = .gray
//        tmapTrafficLine.showTrafficInfo = true
//        tmapTrafficLine.showDirectionIndicator = true
        tmapTrafficLine.width = 6
        tmapTrafficLine.outlineWidth = 2
        tmapTrafficLine.map = mapView
    }
    
//    func addWorkingTrafficLine() {
//        let points: [VSMMapPoint] = [
//            VSMMapPoint(longitude: 126.970833, latitude: 37.554722), // 서울역
//            VSMMapPoint(longitude: 126.977945, latitude: 37.566295), // 시청
//            VSMMapPoint(longitude: 127.009500, latitude: 37.571600), // 동대문
//            VSMMapPoint(longitude: 127.060240, latitude: 37.630420)  // 월계
//        ]
//        var trafficLines: [TrafficLine] = []
//
//        for i in 0..<(points.count - 1) {
//            let trafficLine = TrafficLine()
//            trafficLine.vertices = [points[i], points[i + 1]]
//            
//            trafficLines.append(trafficLine)
//        }
//
//        let trafficShape = TMapTrafficLine(trafficLine: trafficLines)
//       
//        trafficShape.showTrafficInfo = true // ✅ 이게 꺼져 있으면 절대 안 보임
//        trafficShape.showDirectionIndicator = true
//        trafficShape.nextColor = .blue
//        trafficShape.prevColor = .gray
//        trafficShape.nextOutlineColor = .white
//        trafficShape.prevOutlineColor = .lightGray
//        trafficShape.width = 8
//        trafficShape.outlineWidth = 4
//        trafficShape.map = mapView  // ✅ 반드시 먼저 지정
//    }
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
