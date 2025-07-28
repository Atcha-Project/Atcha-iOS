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
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm"
        ]
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = format
            if let date = formatter.date(from: self) {
                let output = DateFormatter()
                output.locale = Locale(identifier: "ko_KR")
                output.dateFormat = "HH:mm"
                return output.string(from: date)
            }
        }
        
        return ""
    }
}

extension String {
    func toHourMinute() -> (hour: Int, minute: Int)? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        guard let date = formatter.date(from: self) else { return nil }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        return hour == 0 ? (24, minute) : (hour, minute)
    }
}
