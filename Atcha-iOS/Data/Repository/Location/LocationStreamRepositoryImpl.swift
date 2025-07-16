//
//  LocationStreamRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation

final class LocationStreamRepositoryImpl: LocationStreamRepository {
    private var updateTask: Task<Void, Never>?
    private var continuation: AsyncStream<CLLocation>.Continuation?
    
    func observeLocationStream() -> AsyncStream<CLLocation> {
        return AsyncStream { continuation in
            self.continuation = continuation
            updateTask = Task {
                do {
                    if #available(iOS 17.0, *) {
                        for try await update in CLLocationUpdate.liveUpdates() {
                            if let location = update.location {
                                continuation.yield(location)
                            }
                        }
                    } else {
                        // Fallback on earlier versions
                    }
                } catch {
                    print("Location live update failed: \(error)")
                }
            }
        }
    }

    func stopLocationUpdates() {
        updateTask?.cancel()
        continuation?.finish()
        continuation = nil
    }
}
