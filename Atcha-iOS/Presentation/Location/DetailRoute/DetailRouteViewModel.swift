//
//  DetailRouteViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import Foundation

final class DetailRouteViewModel: BaseViewModel {
    @Published var infos: ([LegPathInfo], [LegTrafficInfo])
    
    init(infos: ([LegPathInfo], [LegTrafficInfo])) {
        self.infos = infos
        
        super.init()
        self.bind()
    }
    
    private func bind() {
        
    }
}
