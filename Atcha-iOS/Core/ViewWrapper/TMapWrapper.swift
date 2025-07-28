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
    
    func addTrafficLine(passShape: String, color: UIColor, markerImage: UIImage? = nil) {
        let vertices = passShape.split(separator: " ").compactMap { pair -> VSMMapPoint? in
            let parts = pair.split(separator: ",")
            guard parts.count == 2,
                  let lon = Double(parts[0]),
                  let lat = Double(parts[1]) else { return nil }
            return VSMMapPoint(longitude: lon, latitude: lat)
        }
        
        guard vertices.count > 1 else { return }
        
        let trafficLine = TrafficLine()
        trafficLine.vertices = vertices
        
        let tmapTrafficLine = TMapTrafficLine(trafficLine: [trafficLine])
        tmapTrafficLine.prevColor = color
        tmapTrafficLine.nextColor = color
        tmapTrafficLine.width = 6
        tmapTrafficLine.outlineWidth = 0
        tmapTrafficLine.showTrafficInfo = false
        tmapTrafficLine.showDirectionIndicator = true
        tmapTrafficLine.map = mapView
        
        trafficLines.append(tmapTrafficLine)
        
        if let image = markerImage, let start = vertices.first {
            let marker = TMapMarker(position: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude))
            marker.icon = image
            marker.map = mapView
            trafficMarkers.append(marker)
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
