import Foundation

/// 서버 refresh 결과와 현재 세션을 대조해 **다음 세션 상태를 하나 정한다.**
///
/// 존재 이유는 만료 판정이 세 주체에 흩어져 있었다는 것이다 — 홈 ViewModel의 미래시각
/// 가드, 동기화 서비스의 로컬 만료 확정, 스냅샷 톰스톤. 판정 *함수*는 이미
/// `AlarmTiming.isSessionExpired` 하나였는데 그걸 *호출해 결정하는 주체*가 셋이라
/// "1차 방어 / 2차 방어" 같은 주석이 붙었다.
///
/// I/O가 없는 순수 함수라, 이전에는 네트워크·스토어·LA·노티 스텁을 다 조립해야
/// 검증할 수 있던 조합을 표 하나로 확인할 수 있다.
public enum AlarmSessionReconciler {
    public enum Outcome: Sendable, Equatable {
        /// 세션을 이 값으로 갱신한다.
        case refreshed(AlarmSession)
        /// 세션이 죽었다 — 톰스톤으로 남긴다(지우지 않는다).
        case expired(AlarmSession)
        /// 이미 끝난 세션의 메아리 — 아무것도 하지 않는다.
        /// 지운 세션을 refresh가 되살리는 것을 막는 지점이다.
        case ignoredStaleEcho
        /// 서버가 세션 없음을 알렸다 — 로컬 기록까지 정리한다.
        case ended
    }

    /// - Parameters:
    ///   - current: 로컬이 아는 세션(없으면 nil).
    ///   - server: refresh 결과. 실패·오프라인이면 nil을 넘긴다 —
    ///             그때도 로컬 만료 판정은 돌아야 한다.
    ///   - now: 주입된 현재 시각(실 `Date()` 의존 금지 규약).
    public static func reconcile(
        current: AlarmSession?,
        server: AlarmInfo?,
        now: Date
    ) -> Outcome {
        switch (current, server) {
        case (nil, nil):
            return .ended

        // 로컬에 기록이 없고 서버에 세션이 있다 — 재실행 후 발견이거나 첫 sync다.
        // 로컬 사실을 모르므로 `.empty`로 시작하고, 다음 등록이 채운다.
        case let (nil, .some(info)):
            let discovered = AlarmSession(server: info, local: .empty, syncedAt: now)
            return expiryOutcome(for: discovered, now: now) ?? .refreshed(discovered)

        // 서버 응답이 없다(실패·오프라인). 세션을 버리지 않고 **로컬 만료만** 판정한다 —
        // 네트워크 실패가 "데이터가 조금 오래됨"에 그쳐야 하고 "세션 소멸"이 되면 안 된다.
        case let (.some(session), nil):
            if session.isEnded { return .ignoredStaleEcho }
            return expiryOutcome(for: session, now: now) ?? .refreshed(session)

        case let (.some(session), .some(info)):
            return reconcile(session: session, server: info, now: now)
        }
    }

    // MARK: -

    private static func reconcile(
        session: AlarmSession,
        server info: AlarmInfo,
        now: Date
    ) -> Outcome {
        let merged = session.merging(server: info, syncedAt: now)

        // 톰스톤 처리. 같은 경로가 미래 출발 시각을 들고 오면 **서버가 이기므로**
        // 만료를 해제하고 되살린다(서버 우선 규약). 과거 시각이면 메아리로 무시한다.
        if session.isEnded {
            guard info.lastRouteId != session.server.lastRouteId else {
                return merged.hasPassedDeparture(now: now)
                    ? .ignoredStaleEcho
                    : .refreshed(merged.with(lifecycle: .active))
            }
            // 다른 경로 = 새 세션이다. 톰스톤과 무관하게 채택한다.
            let fresh = AlarmSession(server: info, local: .empty, syncedAt: now)
            return expiryOutcome(for: fresh, now: now) ?? .refreshed(fresh)
        }

        // 서버가 출발 시각을 안 줬다 — 세션이 서버에서 사라진 것으로 본다.
        guard info.departureTime != nil else { return .ended }

        return expiryOutcome(for: merged, now: now) ?? .refreshed(merged)
    }

    /// 만료 판정이 일어나는 **유일한 지점**. 만료면 톰스톤 세션을 담은 outcome을,
    /// 아니면 nil을 돌려준다(호출자가 정상 경로를 계속한다).
    ///
    /// `syncedAt`은 보존한다 — 만료 전환이 "마지막으로 서버에 확인한 시각"을 바꾸지는
    /// 않기 때문이다. 신선도 스탬프가 만료 순간으로 튀면 사용자에게 거짓말이 된다.
    private static func expiryOutcome(for session: AlarmSession, now: Date) -> Outcome? {
        guard session.hasPassedDeparture(now: now) else { return nil }
        return .expired(session.with(lifecycle: .ended))
    }
}
