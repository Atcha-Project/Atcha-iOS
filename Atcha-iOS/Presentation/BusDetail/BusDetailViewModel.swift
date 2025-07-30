//
//  BusDetailViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/29/25.
//

import Foundation
import UIKit

final class BusDetailViewModel: BaseViewModel {
    let routeName: String
    let busType: BusType
    let busNumber: String
    let startStation: addressInfo?
    let passStopList: [passStopList]?

    init(busDetailInfo: BusDetailInfo) {
        self.routeName = busDetailInfo.route ?? ""

        let split = self.routeName.splitRouteName()
        self.busType = BusType(from: split.type)
        self.busNumber = split.number
        self.startStation = busDetailInfo.start
        self.passStopList = busDetailInfo.passStopList

        super.init()
    }
    
    var icon: UIImage {
        return busType.icon
    }
}
