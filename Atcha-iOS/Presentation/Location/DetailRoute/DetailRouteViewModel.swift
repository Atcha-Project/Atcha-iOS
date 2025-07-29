//
//  DetailRouteViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import Foundation

final class DetailRouteViewModel: BaseViewModel {
    
    private let routeId: String?
    @Published var isViewDidLoaded: Bool = false
    
    init(routeId: String?) {
        self.routeId = routeId
        
        super.init()
    }
}
