import Foundation

/// 서버 시각은 타임존 표기 없는 KST 문자열이다 (실측: "yyyy-MM-dd'T'HH:mm:ss").
enum ServerDateParser {
    static func date(from string: String) -> Date? {
        // DateFormatter는 Sendable이 아니므로 호출마다 새로 만든다.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        for format in ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
}
