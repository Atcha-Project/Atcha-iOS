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
    case fifteenMinute = 15
    case thirtyMinute = 30
    case oneHour = 60
    
    var title: String {
        switch self {
        case .oneMinute: return "1분 전"
        case .fiveMinute: return "5분 전"
        case .tenMinute: return "10분 전"
        case .fifteenMinute: return  "15분 전"
        case .thirtyMinute: return "30분 전"
        case .oneHour: return "1시간 전"
        }
    }
    
    static var displayOptions: [AlarmTimeOption] {
        return [.fiveMinute, .tenMinute, .fifteenMinute, .thirtyMinute, .oneHour]
    }
}
