//
//  BusDetailViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/29/25.
//

import Foundation

final class BusDetailViewModel: BaseViewModel {
    let busRouteId: String
    let routeName: String
    
    init(busRouteId: String, routeName: String) {
        self.busRouteId = busRouteId
        self.routeName = routeName
        super.init()
    }
}
