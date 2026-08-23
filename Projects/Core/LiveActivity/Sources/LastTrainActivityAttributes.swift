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
    /// 탑승 수단 (Phase 14) — DI 컴팩트 아이콘 분기용. 고정 정보라 Attributes가 맞는 자리.
    /// optional인 이유: 구버전이 남긴 활성 LA의 재부착 디코딩이 새 키 부재로 깨지면 안 된다.
    public let transportKind: LastTrainTransportKind?
    /// 등록 시점 경로의 첫 도보 구간(초, Phase 14) — 잠금화면 3행 "정류장 도보 N분" 표시용.
    public let firstWalkSeconds: Int?

    public init(
        routeId: String,
        routeName: String,
        transportKind: LastTrainTransportKind?,
        firstWalkSeconds: Int?
    ) {
        self.routeId = routeId
        self.routeName = routeName
        self.transportKind = transportKind
        self.firstWalkSeconds = firstWalkSeconds
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

/// 탑승 수단 (Phase 14) — 위젯 아이콘 키. 세분류(간선/지선 등)는 표시에 불필요해
/// 버스/지하철 2종 + 방어값(other)만 둔다. 미지 rawValue 디코딩 실패는 어댑터가
/// optional 필드로 무해화한다(위젯은 nil이면 버스 아이콘 폴백).
public enum LastTrainTransportKind: String, Codable, Hashable, Sendable {
    case bus
    case subway
    case other
}

/// 긴급도 3단계 (여유/주의/임박).
public enum LastTrainUrgency: String, Codable, Hashable, Sendable {
    case relaxed
    case caution
    case imminent
}

/// 세션 상태. `departed` = 알람 발화 확인("지금 출발하세요" — Phase 13 신설),
/// `missed` = 못 타게 됨(앞당겨짐이 이미 비행동 가능),
/// `serviceEnded` = 운행 종료·경로 소멸.
/// 케이스 추가는 wire 안전 — 앱·익스텐션 동일 바이너리 배포이고, 방어값 정책상
/// 미지 rawValue는 `.active`로 떨어진다(어댑터의 rawValue 매핑 참조).
public enum LastTrainSessionStatus: String, Codable, Hashable, Sendable {
    case active
    case departed
    case missed
    case serviceEnded
}
