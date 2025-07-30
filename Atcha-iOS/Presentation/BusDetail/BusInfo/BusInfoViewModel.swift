//
//  BusInfoViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/29/25.
//

import Foundation
import UIKit

final class BusInfoViewModel: BaseViewModel {
    let busType: BusType
    let busNumber: String
    private let busInfoUseCase: BusInfoUseCase
    let busDetailInfo: BusDetailInfo
    
    init(
        busInfoUseCase: BusInfoUseCase,
        busDetailInfo: BusDetailInfo
    ) {
        self.busInfoUseCase = busInfoUseCase
        
        guard let routeName = busDetailInfo.routeName else {
            fatalError("routeName is nil")
        }
        let split = routeName.splitRouteName()
        self.busType = BusType(from: split.type)
        self.busNumber = split.number
        self.busDetailInfo = busDetailInfo
        
        super.init()
    }
    
    var icon: UIImage {
        return busType.icon
    }
}
