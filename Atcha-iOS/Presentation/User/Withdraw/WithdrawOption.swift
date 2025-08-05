//
//  WithdrawOption.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/5/25.
//

import Foundation

enum WithdrawOption: String, CaseIterable {
    case notMatchingTime = "막차 시간이 안맞아요"
    case rarelyUse = "막차를 자주 안 타요"
    case tooManyErrors = "잦은 에러를 겪었어요"
    case inconvenientSearch = "막차를 찾기가 번거로워요"
    case dontKnowHowToUse = "앱 사용법을 모르겠어요"
    case enoughWithOtherApp = "기존에 쓰던 지도 앱으로 충분해요"
    case etc = "기타"
    
    var title: String { rawValue }
}
