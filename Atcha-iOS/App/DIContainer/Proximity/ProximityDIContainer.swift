//
//  ProximityDIContainer.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/18/25.
//

import UIKit
import Foundation

final class ProximityDIContainer {
    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func makeProximityViewModel() -> ProximityViewModel {
        ProximityViewModel()
    }

    func makeProximityViewController(viewModel: ProximityViewModel) -> ProximityViewController {
        return ProximityViewController(viewModel: viewModel)
    }
}
