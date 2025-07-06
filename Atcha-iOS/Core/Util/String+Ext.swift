//
//  String+Ext.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/3/25.
//

import Foundation

extension String {
    // MARK: - 문자열에서 HH:mm 으로 시간 추출
    var convertedToHourMinute: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: self) {
            let output = DateFormatter()
            output.locale = Locale(identifier: "ko_KR")
            output.dateFormat = "HH:mm"
            return output.string(from: date)
        }
        return ""
    }
}
