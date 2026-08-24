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

    /// 클라 자체 만료 유예 — 출발 시각 + 60초가 지나면 세션을 로컬 만료로 판정한다
    /// (wake 시점 판정: AlarmSyncService 진입점 / 깨어 있을 때: 홈 배너 틱).
    public static let expiryGraceSeconds: TimeInterval = 60

    /// 만료 판정 순수 함수 — 시각 주입 테스트용(실 Date() 의존 금지 규약).
    /// 경계(정확히 출발+60초)는 만료로 본다 — 홈 배너 2단계(now < 출발+유예)와 상보적이다.
    /// 서버 refresh가 미래 출발 시각을 주면 호출자가 만료를 취소한다(서버 우선).
    public static func isSessionExpired(departureTime: Date, now: Date) -> Bool {
        now >= departureTime.addingTimeInterval(expiryGraceSeconds)
    }
}
