//
//  AlarmSettingItem.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import Foundation

enum AlarmSettingItem: CaseIterable, MyPageProtocol {
    case soundType
    case frequent
    
    var title: String {
        switch self {
        case .soundType: return "진동/벨소리 설정"
        case .frequent: return "푸시 알림 빈도 설정"
        }
    }
    
    var type: AtchaListType {
        return .arrow
    }
}
