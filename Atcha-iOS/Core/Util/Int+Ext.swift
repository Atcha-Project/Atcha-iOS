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
