import Foundation

/// 버퍼 = 스누즈 예산 (정책 5). 알람은 기준 시각 − 버퍼에 울린다. 버퍼 고정 3분, 설정 없음(v1).
/// TODO(미확정 #7): 기준 시각 = departureTime − 첫 도보 구간 시간이 원칙이나, refresh 응답에
/// 도보 정보가 없어 register/refresh 이중 시각이 생기므로 확정 전까지 버퍼만 균일 적용한다.
public enum AlarmTiming {
    public static let bufferSeconds: TimeInterval = 180

    /// 로컬 알람 발화 시각 = departureTime − bufferSeconds.
    public static func alarmFireDate(departureTime: Date) -> Date {
        departureTime.addingTimeInterval(-bufferSeconds)
    }
}
