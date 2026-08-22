import ActivityKit
import Foundation

// Live Activity contract shared by the app process (start/update/end via the
// ActivityKit adapter) and the widget extension (rendering). Pure data only —
// urgency/diff policy lives in Domain, presentation lives in the extension.

/// Fixed facts of one last-train session, set when the Activity starts.
public struct LastTrainActivityAttributes: ActivityAttributes, Sendable {
    public let routeId: String
    /// 노선명 (예: "9호선 급행") — 잠금화면·다이나믹 아일랜드 타이틀.
    public let routeName: String

    public init(routeId: String, routeName: String) {
        self.routeId = routeId
        self.routeName = routeName
    }

    /// Mutable snapshot pushed on every update.
    public struct ContentState: Codable, Hashable, Sendable {
        /// 막차 출발 시각.
        public let departureTime: Date
        /// 로컬 알람 발화 시각 (기준 시각 − 버퍼).
        public let alarmTime: Date
        /// 긴급도 3단계 — 임계 계산은 Domain, 여기는 결과 값만 나른다.
        public let urgency: LastTrainUrgency
        /// "⚠ 당겨짐" 배지 노출 만료 시각. nil이면 배지 없음.
        public let changeBadgeExpiry: Date?
        /// 세션 상태 (final state 전환 포함).
        public let status: LastTrainSessionStatus

        public init(
            departureTime: Date,
            alarmTime: Date,
            urgency: LastTrainUrgency,
            changeBadgeExpiry: Date?,
            status: LastTrainSessionStatus
        ) {
            self.departureTime = departureTime
            self.alarmTime = alarmTime
            self.urgency = urgency
            self.changeBadgeExpiry = changeBadgeExpiry
            self.status = status
        }
    }
}

/// 긴급도 3단계 (여유/주의/임박).
public enum LastTrainUrgency: String, Codable, Hashable, Sendable {
    case relaxed
    case caution
    case imminent
}

/// 세션 상태. `missed` = 못 타게 됨(앞당겨짐이 이미 비행동 가능),
/// `serviceEnded` = 운행 종료·경로 소멸.
public enum LastTrainSessionStatus: String, Codable, Hashable, Sendable {
    case active
    case missed
    case serviceEnded
}
