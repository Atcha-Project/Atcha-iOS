//
//  LockViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/30/25.
//

import Combine
import Foundation

final class LockViewModel: BaseViewModel {
    @Published private(set) var taxiFare: Int
    var routerHandler: ((MainRoute) -> Void)?
    
    private var lockScreenWorkItem: DispatchWorkItem?

    init(taxiFare: Int) {
        self.taxiFare = taxiFare
        super.init()
        scheduleLockScreen()
    }
    
    // MARK: - 택시 요금 업데이트
    func updateTaxiFare(to newFare: Int) {
        taxiFare = newFare
    }
    
    // MARK: - 120초 후 실행 예약
    private func scheduleLockScreen() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.executeAfterTwoMinutes()
        }
        lockScreenWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 120, execute: workItem)
    }
    
    // MARK: - 타이머 취소
    func cancelLockScreenTimer() {
        lockScreenWorkItem?.cancel()
        lockScreenWorkItem = nil
    }
    
    private func executeAfterTwoMinutes() {
        routerHandler?(.lockScreen(info: nil, address: nil))
    }
}
