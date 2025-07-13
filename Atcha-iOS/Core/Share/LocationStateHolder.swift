//
//  LocationStateHolder.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/9/25.
//

import Foundation
import Combine
import CoreLocation

final class LocationStateHolder {
    let currentLocationSubject = PassthroughSubject<CLLocationCoordinate2D, Never>()
    
    var currentLocation: CLLocationCoordinate2D?
    var address: String?
    var buildingName: String?
}
