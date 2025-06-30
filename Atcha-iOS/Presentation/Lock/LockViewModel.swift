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
    
}
