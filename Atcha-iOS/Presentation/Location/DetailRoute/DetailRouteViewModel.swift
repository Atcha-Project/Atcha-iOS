//
//  DetailRouteViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import Foundation
import UIKit

final class DetailRouteViewModel: BaseViewModel {
    @Published var address: String
    private let infos: LegInfo
    @Published var legtPathInfo: [LegPathInfo] = []
    @Published var legTrafficInfo: [LegTrafficInfo] = []
    
    init(address: String, infos: LegInfo) {
        self.infos = infos
        self.address = address
        
        super.init()
        self.bind()
    }
    
    private func bind() {
        self.legtPathInfo = infos.pathInfo
        self.legTrafficInfo = infos.trafficInfo
    }
}
