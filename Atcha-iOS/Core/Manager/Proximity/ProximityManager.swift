//
//  Manager.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/18/25.
//

import Foundation
import CoreLocation

// MAKR: - 직선거리 기반 근접 판별 매니저
final class ProximityManager {

    // 판별 임계값(미터). 기본 1km.
    private let threshold: CLLocationDistance
    static let shared = ProximityManager(thresholdMeters: 800)

    init(thresholdMeters: CLLocationDistance = 800) {
        self.threshold = thresholdMeters
    }

    // MARK: - 두 좌표의 직선거리가  1Km 이내인지
    func isWithinThreshold(from: CLLocationCoordinate2D,
                           to: CLLocationCoordinate2D) -> Bool {
        guard isValid(from), isValid(to) else { return false }
        return distanceMeters(from: from, to: to) <= threshold
    }

    // MARK: - 두 좌표의 직선거리(미터)
    func distanceMeters(from: CLLocationCoordinate2D,
                        to: CLLocationCoordinate2D) -> CLLocationDistance {
        let a = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let b = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return a.distance(from: b) // 미터 단위
    }
    
    // MARK: - 유요한 위도/경도 인지 체크
    private func isValid(_ coord: CLLocationCoordinate2D) -> Bool {
        CLLocationCoordinate2DIsValid(coord)
    }
}
