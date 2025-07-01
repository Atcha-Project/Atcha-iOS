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
    
    init(taxiFare: Int) {
        self.taxiFare = taxiFare
    }
    
    // MARK: - 택시 요금 업데이트
    func updateTaxiFare(to newFare: Int) {
        taxiFare = newFare
    }
    
    // MARK: - 택시 요금 포맷 변환
    var formattedTaxiFare: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: taxiFare)) ?? "\(taxiFare)"
    }
    
}
