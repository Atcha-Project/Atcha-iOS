//
//  LocationSmoother.swift
//  Atcha-iOS
//
//  Created by wodnd on 3/11/26.
//

import Foundation
import CoreLocation
import MapKit

final class LocationSmoother {
    private var buffer: [CLLocationCoordinate2D] = []
    private let bufferLimit: Int

    init(limit: Int = 5) {
        self.bufferLimit = limit
    }

    func smooth(_ next: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        buffer.append(next)
        if buffer.count > bufferLimit { buffer.removeFirst() }

        let avgLat = buffer.map { $0.latitude }.reduce(0, +) / Double(buffer.count)
        let avgLon = buffer.map { $0.longitude }.reduce(0, +) / Double(buffer.count)

        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }
}

extension LocationSmoother {
    /// 좌표를 경로선(Polyline) 위 가장 가까운 점으로 고정합니다.
    func snap(current: CLLocationCoordinate2D, polyline: [CLLocationCoordinate2D], threshold: Double = 150) -> CLLocationCoordinate2D {
        guard polyline.count >= 2 else { return current }
        
        let p = MKMapPoint(current)
        var minDistance = Double.greatestFiniteMagnitude
        var closestPoint = p
        
        for i in 0..<(polyline.count - 1) {
            let a = MKMapPoint(polyline[i])
            let b = MKMapPoint(polyline[i + 1])
            
            let projected = closestPointOnSegment(p, a, b)
            let distance = projected.distance(to: p)
            
            if distance < minDistance {
                minDistance = distance
                closestPoint = projected
            }
        }
        
        // 임계값(150m) 보다 멀어지면 사용자가 경로를 이탈한 것으로 간주하여 원본 좌표 반환
        return minDistance < threshold ? closestPoint.coordinate : current
    }
    
    private func closestPointOnSegment(_ p: MKMapPoint, _ a: MKMapPoint, _ b: MKMapPoint) -> MKMapPoint {
        let dx = b.x - a.x
        let dy = b.y - a.y
        if dx == 0 && dy == 0 { return a }
        
        let t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / (dx * dx + dy * dy)
        if t < 0 { return a }
        if t > 1 { return b }
        return MKMapPoint(x: a.x + t * dx, y: a.y + t * dy)
    }
}
