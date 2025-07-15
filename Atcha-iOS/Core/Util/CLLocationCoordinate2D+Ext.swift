//
//  CLLocationCoordinate2D+Ext.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/15/25.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        abs(lhs.latitude - rhs.latitude) < 0.0001 &&
        abs(lhs.longitude - rhs.longitude) < 0.0001
    }
}
