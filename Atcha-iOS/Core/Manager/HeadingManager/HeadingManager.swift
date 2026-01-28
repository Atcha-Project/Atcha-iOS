//
//  HeadingManager.swift
//  Atcha-iOS
//
//  Created by wodnd on 1/27/26.
//

import Foundation
import CoreLocation

final class HeadingManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onHeading: ((CLLocationDirection) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = 1
    }

    func start() {
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        guard heading >= 0 else { return }
        onHeading?(heading)
    }
}
