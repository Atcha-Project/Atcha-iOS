//
//  AlarmTimeOption.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/12/25.
//

import Foundation

enum AlarmTimeOption: Int, CaseIterable {
    case oneMinute = 1
    case fiveMinute = 5
    case tenMinute = 10
    case twentyMinute = 20
    
    var title: String {
        switch self {
        case .oneMinute: return "1분 전"
        case .fiveMinute: return "5분 전"
        case .tenMinute: return  "10분 전"
        case .twentyMinute: return "20분 전"
        }
    }
}
