import Foundation

/// Phase 11 — 막차 변경 인지 계층의 사용자 대면 문구 단일 소스(정책: 하드코딩 상수, 한 파일).
/// Live Activity alert(잠금화면)와 Phase 12 로컬 노티 폴백(LA dismiss 시)이 같은 문구를 공유한다.
/// nonisolated: 발신처가 액터 경계를 넘나든다(@MainActor AlarmSyncService·actor LA 어댑터·
/// Phase 12 노티 빌더) — 어디서든 동기 접근 가능해야 한다.
nonisolated enum LastTrainChangeMessages {

    // MARK: - 당겨짐 (advanced, actionable) — 행동 중심 문구

    /// LA alert 제목: "N분 일찍 나가야 해요"
    static func advancedAlertTitle(minutesEarlier: Int) -> String {
        "\(minutesEarlier)분 일찍 나가야 해요"
    }

    /// LA alert 본문: "막차가 HH:mm → HH:mm로 당겨졌어요"
    static func advancedAlertBody(from previousDeparture: Date, to latestDeparture: Date) -> String {
        "막차가 \(timeText(previousDeparture)) → \(timeText(latestDeparture))로 당겨졌어요"
    }

    // MARK: - 최후통첩 — 당겨진 새 알람 시각이 이미 과거(출발은 미래)인 마지노선 침범

    static let ultimatumTitle = "지금 안 나가면 못 타요"

    static func ultimatumBody(latestDeparture: Date) -> String {
        "막차가 \(timeText(latestDeparture)) 출발로 당겨졌어요. 바로 출발하세요"
    }

    // MARK: - 못 탐 (advanced, actionable: false) — 당겨진 출발 시각이 이미 과거 (Phase 12)

    /// LA 실패 상태(missed) 전환 alert와 dismiss 폴백 로컬 노티가 공유하는 제목.
    static let missedTitle = "막차가 지나갔어요"

    /// TODO(#9 임시 — 문구만): 대안 제시 데이터(심야버스·첫차 등) 확보 시 본문에 대안 안내를 싣는다.
    static func missedBody(latestDeparture: Date) -> String {
        "막차가 \(timeText(latestDeparture))에 이미 출발했어요"
    }

    // MARK: - 범용 폴백 — 문구를 싣지 않는 Domain 포트 경로(update(state:alert: true)) 전용

    static let genericChangeTitle = "막차 정보가 변경됐어요"
    static let genericChangeBody = "잠금화면에서 최신 막차 시간을 확인하세요"

    // MARK: - 시각 표기

    /// HH:mm (24시간 고정, ko_KR) — 사용자 로캘의 12시간제 설정과 무관하게 "23:40" 형태를 보장한다.
    /// 호출 빈도가 낮아(변경 이벤트 시에만) 포매터를 매번 생성한다 — 격리 걱정 없는 가장 단순한 형태.
    static func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
