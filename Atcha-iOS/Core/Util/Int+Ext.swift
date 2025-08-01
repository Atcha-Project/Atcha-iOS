//
//  Int+Ext.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/1/25.
//

import Foundation

extension Int {
    var formattedWithComma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
    
    var toHourMinuteStringFromSeconds: String {
        let totalMinutes = self / 60
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if minutes == 0 {
                return "\(hours)시간"
            } else {
                return "\(hours)시간 \(minutes)분"
            }
        } else {
            return "\(totalMinutes)분"
        }
    }
}

extension Int {
    var toHourMinuteSecondString: String {
        if self <= 0 { return "0초" }
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        } else {
            return "\(seconds)초"
        }
    }
}
