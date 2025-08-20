//
//  LoginItnro.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/20/25.
//

import UIKit

enum LoginIntro: CaseIterable {
    case step1
    case step2
    case step3
    case step4
    case step5
    
    var title: String {
        switch self {
        case .step1:
            return "번거롭던 막차 찾기\n이제 두 단계면 충분해요"
        case .step2:
            return "우리집 미리 등록 해두고\n출발지만 선택해요"
        case .step3:
            return "푸시 알람으로\n남은 시간 알려드릴게요"
        case .step4:
            return "지금 몇시지? 하지 마세요\n출발 알람 받고 막차 타러 출발!"
        case .step5:
            return "이제 경로만 따라가면 돼요\n안전하게 귀가해요"
        }
    }
    
    var image: UIImage {
        switch self {
        case .step1: return UIImage.step1
        case .step2: return UIImage.step2
        case .step3: return UIImage.step3
        case .step4: return UIImage.step4
        case .step5: return UIImage.step5
        }
    }
}
