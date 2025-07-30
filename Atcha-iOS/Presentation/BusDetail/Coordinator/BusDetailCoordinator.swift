//
//  BusDetailCoordinator.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation
import UIKit
import Combine

final class BusDetailCoordinator {
    var navigationController: UINavigationController
    private var cancellables = Set<AnyCancellable>()
    private let diContainer: BusInfoDIContainer
    
    init(navigationController: UINavigationController,
         diContainer: BusInfoDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }
    
    func start() {
        
    }
}

