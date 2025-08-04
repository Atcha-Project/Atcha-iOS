//
//  LockViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/30/25.
//

import Foundation
import Combine

final class LockViewModel: BaseViewModel {
    @Published private(set) var taxiFare: Int
    
    var routerHandler: ((SplashRouter) -> Void)?
    
    init(taxiFare: Int) {
        self.taxiFare = taxiFare
        
        super.init()
    }
    
    // MARK: - 택시 요금 업데이트
    func updateTaxiFare(to newFare: Int) {
        taxiFare = newFare
    }
}
