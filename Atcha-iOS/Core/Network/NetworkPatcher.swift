//
//  NetworkPatcher.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/22/25.
//

import Foundation
import Network

final class NetworkPatcher {
    static let shared = NetworkPatcher()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    private(set) var isConnected: Bool = true
    var onStatusChange: ((Bool) -> Void)?
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let newStatus = (path.status == .satisfied)
            
            if newStatus != self.isConnected {
                self.isConnected = newStatus
                DispatchQueue.main.async {
                    self.onStatusChange?(newStatus)
                }
            }
        }
        monitor.start(queue: queue)
    }
}
