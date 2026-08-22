import Foundation

/// Live Activity 표시용 긴급도 — 잠금화면·다이나믹 아일랜드의 색상·강조 단계 키.
public enum LastTrainUrgency: String, Sendable, Equatable {
    case relaxed
    case caution
    case imminent

    /// 남은 시간(초) → 긴급도. 임계는 디자이너 확정 전 제안값: ≤10분 imminent, ≤30분 caution.
    /// HomeViewModel.makeBanner의 "10분" 제안값(분 단위 ceil ≤ 10)과 같은 경계다 — 600초 이하면 imminent.
    /// 음수(이미 지난 시각)도 imminent로 취급한다.
    public static func forTimeRemaining(_ seconds: TimeInterval) -> LastTrainUrgency {
        if seconds <= 10 * 60 { return .imminent }
        if seconds <= 30 * 60 { return .caution }
        return .relaxed
    }
}

/// 알람 세션 단계 — active(진행 중) / missed(막차 놓침) / serviceEnded(운행 종료).
public enum LastTrainSessionPhase: String, Sendable, Equatable {
    case active
    case missed
    case serviceEnded
}

/// Live Activity 콘텐츠 상태 — LA 어댑터(App)가 이 값만 보고 잠금화면·다이나믹 아일랜드를 그린다.
public struct LastTrainActivityState: Sendable, Equatable {
    /// 막차 출발 시각
    public let departureTime: Date
    /// 로컬 알람 발화 시각
    public let alarmTime: Date
    public let urgency: LastTrainUrgency
    /// "⚠ 당겨짐" 배지 만료 시각 (Phase 11 전까진 nil)
    public let changeBadgeExpiry: Date?
    public let phase: LastTrainSessionPhase

    public init(
        departureTime: Date,
        alarmTime: Date,
        urgency: LastTrainUrgency,
        changeBadgeExpiry: Date?,
        phase: LastTrainSessionPhase
    ) {
        self.departureTime = departureTime
        self.alarmTime = alarmTime
        self.urgency = urgency
        self.changeBadgeExpiry = changeBadgeExpiry
        self.phase = phase
    }
}
