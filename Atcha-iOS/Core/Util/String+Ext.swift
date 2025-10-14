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
    func toHourMinute() -> (hour: String, minute: String)? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        guard let date = formatter.date(from: self) else { return nil }
        
        let calendar = Calendar.current
        var hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        if hour == 0 { hour = 24 }
        
        return (String(format: "%02d", hour), String(format: "%02d", minute))
    }
}


extension String {
    // MARK: - 버스명, 버스번호 분리
    func splitRouteName() -> (type: String, number: String) {
        let components = self.split(separator: ":").map { String($0) }
        let type = components.first ?? ""
        let number = components.count > 1 ? components[1] : ""
        return (type, number)
    }
}

extension String {
    // MARK: - 요일 한글로 변경
    func dayToKorean() -> String {
        switch self {
        case "WEEKDAY": return "평일"
        case "SATURDAY": return "토요일"
        case "HOLIDAY": return "공휴일"
        default: return self
        }
    }
}


extension String {
    // MARK: - 서비스 지역 한글로 변경
    func serviceRegionToKorean() -> String {
        switch self.uppercased() {
        case "SEOUL":
            return "서울"
        case "GYEONGGI":
            return "경기"
        case "INCHEON":
            return "인천"
        default:
            return self
        }
    }
}


extension String {
    // MARK: - 문자열에서 HH:mm 으로 시간 추출 (+ 추가 초 계산)
    func convertedToHourMinute(with additionalSeconds: Int = 0) -> String {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm"
        ]
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = format
            if let date = formatter.date(from: self) {
                let arriveDate = date.addingTimeInterval(TimeInterval(additionalSeconds))
                
                let output = DateFormatter()
                output.locale = Locale(identifier: "ko_KR")
                output.dateFormat = "HH:mm"
                return output.string(from: arriveDate)
            }
        }
        
        return ""
    }
}

extension String {
    func versionComponents() -> [Int] {
        return self
            .replacingOccurrences(of: "v", with: "")
            .split(separator: ".")
            .compactMap { Int($0) }
    }
}
