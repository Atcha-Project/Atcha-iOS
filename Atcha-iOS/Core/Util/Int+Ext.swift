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
}
