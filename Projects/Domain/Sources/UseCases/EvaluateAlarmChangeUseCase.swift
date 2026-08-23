import Foundation

/// 막차 변경 판정 결과 — 표출(조용한 업데이트 vs alert)은 어댑터의 몫, 판정만 Domain이 한다.
public enum AlarmChangeVerdict: Sendable, Equatable {
    case unchanged
    /// 늦춰짐 → 조용한 업데이트
    case delayed(by: TimeInterval)
    /// 앞당겨짐 → alert. actionable=false면 이미 못 탐(latest가 과거).
    case advanced(by: TimeInterval, actionable: Bool)
    /// 운행 종료·경로 소멸
    case sessionEnded
}

/// 갱신 전/후 AlarmInfo를 비교해 변경을 판정한다.
/// 스케줄러 상태(scheduledFireDate)가 아니라 **AlarmInfo 전/후 비교**인 이유:
/// 알람 발화 후 scheduledFireDate가 nil이 되어 "변경 없음"이 "변경"으로 오판되기 때문.
public protocol EvaluateAlarmChangeUseCase: Sendable {
    func execute(previous: AlarmInfo, latest: AlarmInfo, now: Date) -> AlarmChangeVerdict
}

public struct DefaultEvaluateAlarmChangeUseCase: EvaluateAlarmChangeUseCase {
    public init() {}

    public func execute(previous: AlarmInfo, latest: AlarmInfo, now: Date) -> AlarmChangeVerdict {
        // 운행 종료·경로 소멸: 서버 재계산 결과에 출발 시각이 없다.
        guard let latestDeparture = latest.departureTime else {
            return .sessionEnded
        }
        // TODO: 첫 수신(이전 값 없음)은 비교 불가 — 변경으로 취급하지 않는다.
        guard let previousDeparture = previous.departureTime else {
            return .unchanged
        }

        let difference = latestDeparture.timeIntervalSince(previousDeparture)
        // 초 단위 동일(서브초 오차 포함)은 변경으로 보지 않는다.
        if abs(difference) < 1 {
            return .unchanged
        }
        if difference < 0 {
            // TODO: [미확정 #7] 원칙은 "now + 첫 도보 구간 시간 < latest"지만 refresh 응답에
            //       이동시간 데이터가 없어, 출발 시각이 아직 미래인지로 보수적으로 근사한다.
            return .advanced(by: -difference, actionable: latestDeparture > now)
        }
        return .delayed(by: difference)
    }
}
