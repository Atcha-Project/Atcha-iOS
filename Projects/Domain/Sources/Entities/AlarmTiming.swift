import Foundation

/// 버퍼 = 스누즈 예산 (정책 5). 알람은 기준 시각 − 버퍼에 울린다. 버퍼 고정 3분, 설정 없음(v1).
/// 기준 시각(미확정 #7 클라 임시안, Phase 14 확정) = departureTime − 첫 도보 구간 시간 —
/// 도보 초는 등록 시점 경로에서 취득해 스냅샷에 저장하고, 서버 필드가 생기면 대체한다.
public enum AlarmTiming {
    public static let bufferSeconds: TimeInterval = 180

    /// 로컬 알람 발화 시각 = departureTime − firstWalkSeconds − bufferSeconds.
    /// 등록/refresh 재스케줄/LA alarmTime/홈 배너 4곳이 전부 이 함수를 탄다(이중 시각 금지) —
    /// 기본값을 두지 않아 콜사이트가 도보 초의 출처(경로·스냅샷·없음)를 명시하게 강제한다.
    public static func alarmFireDate(departureTime: Date, firstWalkSeconds: Int?) -> Date {
        departureTime.addingTimeInterval(
            -(TimeInterval(firstWalkSeconds ?? 0) + bufferSeconds)
        )
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
