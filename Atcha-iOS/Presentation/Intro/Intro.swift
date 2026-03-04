//
//  LoginItnro.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/20/25.
//

import UIKit

enum Intro: CaseIterable {
    case step1
    case step2
    case step3
    case step4
    
    var title: String {
        switch self {
        case .step1:
            return "번거롭던 막차 찾기,\n이제 클릭 한 번이면 돼요"
        case .step2:
            return "늦은 출발순으로\n다양한 막차 경로 확인해요"
        case .step3:
            return "원하는 경로 선택하고\n출발 시간에 알람 받아요"
        case .step4:
            return "경로 보고\n안전하게 귀가해요"
        }
    }
    
    var image: UIImage {
        switch self {
        case .step1: return UIImage.step1
        case .step2: return UIImage.step2
        case .step3: return UIImage.step3
        case .step4: return UIImage.step4
        }
    }
}
