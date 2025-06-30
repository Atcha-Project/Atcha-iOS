//
//  LocationService.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/26/25.
//

import Foundation
import CoreLocation

protocol LocationServiceProtocol {
    func requestLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void)
    func startHeadingUpdates(delegate: CLLocationManagerDelegate)
}

final class LocationService: NSObject, LocationServiceProtocol {
    private let locationManager = CLLocationManager()
    private var completion: ((CLLocationCoordinate2D?) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        self.completion = completion
        
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            completion(nil)
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        completion?(locations.last?.coordinate)
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(nil)
        completion = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func startHeadingUpdates(delegate: CLLocationManagerDelegate) {
        locationManager.delegate = delegate
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.startUpdatingHeading()
    }
    
    func stopHeadingUpdates() {
        locationManager.stopUpdatingHeading()
    }
}
