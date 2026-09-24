/// `refresh()`가 돌려줄 수 있는 답. **`AlarmInfo?` 하나로 뭉개면 안 된다** —
/// "서버가 없다고 답했다"와 "못 물어봤다"가 구분되지 않기 때문이다.
///
/// | 답 | 의미 | 세션 처리 |
/// |---|---|---|
/// | `.registered` | 서버에 세션이 있다 | 병합·재스케줄 |
/// | `.notRegistered` | **서버가 없다고 확정했다** | 로컬 기록까지 정리 |
/// | `throw` | 못 물어봤다(실패·오프라인) | **지킨다** — 네트워크 실패가 세션 소멸이 되면 안 된다 |
///
/// 가운데 칸이 이 타입이 생긴 이유다. 서버는 이 상태를 404 + `URT_001`로 알리는데,
/// 그게 throw로 흘러 "실패"와 같은 취급을 받고 있었다 — 서버가 세션을 잃어도 앱은
/// 낡은 세션을 계속 붙들고, 등록된 알람이 없는 평상시엔 매 실행마다 에러 로그가 찍혔다.
public enum AlarmRefreshOutcome: Sendable, Equatable {
    case registered(AlarmInfo)
    case notRegistered

    /// 값이 필요한 호출처용 — 부재와 실패를 구분할 필요가 없는 자리에서만 쓴다.
    public var info: AlarmInfo? {
        if case let .registered(info) = self { return info }
        return nil
    }
}
