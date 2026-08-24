@preconcurrency import ActivityKit
import CoreLiveActivity
import Domain
import Foundation

/// App 내부 확장 포트 — Phase 11 변경 훅이 alert **문구**를 실어 보내는 경로.
/// Domain 포트(`update(state:alert: Bool)`)는 문서 고정 계약이라 그대로 두고,
/// 변경 유형별 문구가 필요한 호출자(AlarmSyncService)는 이 프로토콜로 어댑터를 본다.
/// nonisolated 명시: App의 기본 MainActor 격리가 요구사항에 스미면 actor 어댑터가
/// 적합성을 만족할 수 없다 — Domain 포트(.nonisolated 모듈)와 같은 조건을 재현한다.
nonisolated protocol LastTrainChangeAlerting: Sendable {
    /// alert가 nil이면 조용한 상태 갱신, 값이 있으면 해당 문구의 AlertConfiguration으로 갱신한다.
    func update(state: LastTrainActivityState, alert: (title: String, body: String)?) async
    /// Phase 12 dismiss 폴백 트리거 — 유저가 잠금화면에서 LA를 스와이프로 지운 기록.
    /// true면 LA alert는 도달 불가(update가 no-op)라 호출자가 로컬 노티로 갈아탄다.
    var isDismissedByUser: Bool { get async }
    /// Phase 15 — LA alert 도달 가능성 단일 판정:
    /// 보유 activity 있음 ∧ areActivitiesEnabled ∧ ¬dismissedByUser.
    /// false면 update(alert:)가 no-op이거나 잠금화면에 표면이 없다 — 호출자는 로컬 노티로
    /// 갈아탄다(채널 갈아타기이지 LA 재생성이 아니다 — push-to-start 금지 정책 불변).
    var isAlertReachable: Bool { get async }
    /// Phase 12 종료 표출 — missed/serviceEnded 최종 상태로 LA를 내린다(Domain 포트와 동일 구현).
    func end(final state: LastTrainActivityState) async
}

/// Phase 13 발화 확인 경로 — stopIntent가 조합 루트(세션 수명 서비스)를 거쳐 LA를
/// departed로 내리는 통로. Domain 포트(`LastTrainActivityPort`)는 문서 고정 계약이라
/// 손대지 않고 App 내부 확장 포트로 둔다(Phase 11의 LastTrainChangeAlerting과 같은 방식).
nonisolated protocol LastTrainDepartureEnding: Sendable {
    /// 현재 세션을 departed("지금 출발하세요") 최종 상태로 전환하고, 출발+유예 시점에
    /// 잠금화면에서 자동 소멸하도록 예약한다 — 앱이 다시 깨지 않아도 시스템이 내린다.
    /// 실패·세션 부재는 흡수한다(포트 계약과 동일 — LA 실패가 확인 기록을 막으면 안 된다).
    func endAsDeparted() async
}

/// Phase 14 재실행 정합성 경로 — 고아 LA 재부착과 죽은 세션 재시작. Domain 포트는
/// 시그니처 고정 계약이라 App 내부 확장 포트로 둔다(재부착은 어댑터 내부 동작).
nonisolated protocol LastTrainSessionRestoring: Sendable {
    /// 부트스트랩 직후 1회 — 프로세스가 죽는 사이 잠금화면에 남은
    /// `Activity.activities`를 스캔해, 스냅샷과 routeId가 일치하고 미만료인 세션은
    /// **adopt**(보관 + 상태 관찰 재개 — 이후 update/end가 정상 동작)하고,
    /// 불일치·만료·스냅샷 없음은 즉시 정리한다.
    func reattachOrphans(snapshot: AlarmSessionSnapshot?, now: Date) async
    /// sync 성공 후 — 스냅샷은 살아 있는데(미만료·미확인) 활성 activity가 없고 dismiss
    /// 기록도 없으면 LA를 로컬 재시작한다. 8시간 한도로 시스템이 내린 세션·시작 실패
    /// 세션 커버 — push-to-start 금지 정책과 무관(그 정책은 유저가 지운 LA의 재생성 금지,
    /// dismiss 기록이 있으면 여기서도 재시작하지 않는다).
    func restartIfNeeded(snapshot: AlarmSessionSnapshot, now: Date) async
}

/// ActivityKit → Domain `LastTrainActivityPort` 어댑터. ActivityKit을 import하는 곳은 App에서 이 파일뿐.
/// 단일 알람 정책과 동일하게 Live Activity도 단일 세션만 유지한다(새 start가 기존 세션을 교체).
/// 포트 계약대로 어떤 실패도 밖으로 던지지 않는다 — LA 실패가 알람 등록·취소를 실패시키면 안 된다.
///
/// actor인 이유: 포트는 nonisolated async 요구사항을 가진 Sendable 프로토콜이라
/// MainActor 클래스의 격리 멤버로는 적합성이 성립하지 않는다(Sendable 경계를 넘는 격리 적합성 불가).
/// ActivityKit의 `Activity`는 Sendable 미표기이나 스레드 안전 설계라 `@preconcurrency`로 완화한다.
actor LastTrainLiveActivityAdapter: LastTrainActivityPort, LastTrainChangeAlerting,
    LastTrainDepartureEnding, LastTrainSessionRestoring {
    /// 유저 스와이프 dismiss 기록 키 — 앱 재실행 후에도 남아야 Phase 12 폴백 트리거 재료가 된다.
    private static let dismissedDefaultsKey = "la.dismissedByUser"

    private let userDefaults: UserDefaults

    /// 단일 세션 — 단일 알람 정책과 동일. 새 start가 이전 activity를 먼저 내린다.
    ///
    /// 알려진 한계(LA 활성 8시간 제한): 출발이 8시간 이상 남은 세션은 시스템이 LA를 먼저
    /// 종료할 수 있다(다이나믹 아일랜드는 더 짧음). 막차 추적은 저녁~심야 용도라 통상 무해하고,
    /// 안전망(로컬 알람)은 LA와 무관하게 유지된다 — 재시작 경로는 두지 않는다(정책: 저빈도, YAGNI).
    private var activity: Activity<LastTrainActivityAttributes>?
    /// `activityStateUpdates` 관찰 태스크 — 프로그램적 end·새 start·deinit에서 cancel.
    private var stateObservationTask: Task<Void, Never>?
    /// 인메모리 기록 + UserDefaults 미러 — 재실행 후에도 조회 가능해야 한다.
    private var dismissedByUser: Bool

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.dismissedByUser = userDefaults.bool(forKey: Self.dismissedDefaultsKey)
    }

    // deinit 없음: AppDIContainer가 앱 수명 동안 1회 생성·보유하므로 해제 경로가 없고,
    // actor deinit에서 격리 상태 접근은 Swift 6에서 제약된다. 관찰 태스크는 end/start에서 정리.

    // MARK: - LastTrainActivityPort

    func start(session: AlarmInfo, route: LastRoute) async {
        // 새 알람 세션 = 새 기록. 이전 세션의 dismiss 기록은 여기서 리셋한다.
        recordDismissedByUser(false)

        // 정책: LA 비활성(설정 꺼짐 등)이면 조용히 no-op — 알람만으로 동작해야 한다.
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // 단일 세션: 기존 activity가 있으면 먼저 내린다. 교체이므로 즉시 제거.
        if let existing = activity {
            stateObservationTask?.cancel()
            stateObservationTask = nil
            activity = nil
            await existing.end(nil, dismissalPolicy: .immediate)
        }

        let departureTime = session.departureTime ?? route.departureTime
        // 로컬 알람 발화 시각 — register/refresh와 동일 기준(출발 − 도보 − 버퍼, Phase 14).
        let alarmTime = AlarmTiming.alarmFireDate(
            departureTime: departureTime,
            firstWalkSeconds: route.firstWalkSectionSeconds
        )
        let initialState = LastTrainActivityState(
            departureTime: departureTime,
            alarmTime: alarmTime,
            // 긴급도는 이후 갱신과 같은 척도인 **알람 시각** 기준(Phase 14 정합 — 최초
            // start만 출발 시각 기준이던 불일치 제거).
            urgency: Domain.LastTrainUrgency.forTimeRemaining(
                alarmTime.timeIntervalSinceNow
            ),
            changeBadgeExpiry: nil,
            phase: .active
        )

        do {
            let requested = try Activity.request(
                attributes: LastTrainActivityAttributes(
                    routeId: route.id,
                    routeName: route.sessionDisplayName,
                    transportKind: Self.transportKind(from: route.boardingLeg?.mode),
                    firstWalkSeconds: route.firstWalkSectionSeconds
                ),
                // staleDate = 출발 시각: 갱신이 끊긴 LA가 출발 시각이 지난 뒤에도
                // 오래된 정보를 신선한 것처럼 보이지 않게 시스템이 stale 처리하도록 방어.
                content: ActivityContent(
                    state: Self.contentState(from: initialState),
                    staleDate: departureTime
                )
            )
            activity = requested
            observeActivityState(requested)
        } catch {
            // LA 시작 실패는 흡수한다(포트 계약) — 알람만으로 동작.
        }
    }

    // MARK: - LastTrainSessionRestoring (Phase 14)

    func reattachOrphans(snapshot: AlarmSessionSnapshot?, now: Date) async {
        // 살아 있는 세션을 이미 보관 중이면(이론상 재부착 전 start 경합) 손대지 않는다.
        var adopted = activity != nil
        for orphan in Activity<LastTrainActivityAttributes>.activities {
            if !adopted,
               // dismiss 기록이 있는 세션은 재부착도 하지 않는다 — 유저가 지운 LA는
               // 어떤 경로로도 되살리지 않는 정책과 한 몸(정상 흐름에선 지워진 LA가
               // 목록에 없지만, 기록·상태가 어긋난 경우에도 지운 의사가 이긴다).
               !dismissedByUser,
               let snapshot, !snapshot.expired,
               orphan.attributes.routeId == snapshot.info.lastRouteId,
               let departure = snapshot.info.departureTime,
               !AlarmTiming.isSessionExpired(departureTime: departure, now: now),
               orphan.activityState == .active || orphan.activityState == .stale {
                // adopt — 보관 + 상태 관찰 재개. 이후 update/end가 정상 동작한다.
                activity = orphan
                observeActivityState(orphan)
                adopted = true
            } else {
                // 불일치·만료·스냅샷 없음(고아) — 잠금화면에서 즉시 정리한다.
                await orphan.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    func restartIfNeeded(snapshot: AlarmSessionSnapshot, now: Date) async {
        // dismiss 존중(유저가 지운 LA 재생성 금지)·확인된 세션(departed 소멸 예약 완료)
        // 재시작 금지. 활성 activity가 있으면 당연히 재시작하지 않는다 — adopt된 세션 포함.
        guard activity == nil,
              !dismissedByUser,
              !snapshot.expired,
              !snapshot.acknowledged,
              let departure = snapshot.info.departureTime,
              !AlarmTiming.isSessionExpired(departureTime: departure, now: now),
              ActivityAuthorizationInfo().areActivitiesEnabled
        else { return }

        let alarmTime = AlarmTiming.alarmFireDate(
            departureTime: departure,
            firstWalkSeconds: snapshot.firstWalkSeconds
        )
        let state = LastTrainActivityState(
            departureTime: departure,
            alarmTime: alarmTime,
            urgency: Domain.LastTrainUrgency.forTimeRemaining(alarmTime.timeIntervalSince(now)),
            changeBadgeExpiry: nil,
            phase: .active
        )
        do {
            let requested = try Activity.request(
                attributes: LastTrainActivityAttributes(
                    routeId: snapshot.info.lastRouteId,
                    routeName: snapshot.routeDisplayName.isEmpty ? "막차" : snapshot.routeDisplayName,
                    transportKind: Self.transportKind(from: snapshot.transportMode),
                    firstWalkSeconds: snapshot.firstWalkSeconds
                ),
                content: ActivityContent(
                    state: Self.contentState(from: state),
                    staleDate: departure
                )
            )
            activity = requested
            observeActivityState(requested)
        } catch {
            // 재시작 실패도 흡수한다 — 알람·홈 배너만으로 동작(포트 계약과 동일 태도).
        }
    }

    func update(state: LastTrainActivityState, alert: Bool) async {
        // 문구 없는 Bool 경로(Domain 포트) — alert=true면 범용 폴백 문구로 위임한다.
        // Phase 11 훅은 이 경로 대신 LastTrainChangeAlerting으로 변경 유형별 문구를 싣는다.
        await update(
            state: state,
            alert: alert
                ? (title: LastTrainChangeMessages.genericChangeTitle,
                   body: LastTrainChangeMessages.genericChangeBody)
                : nil
        )
    }

    func end(final state: LastTrainActivityState) async {
        // 프로그램적 end 이후 도착하는 .dismissed는 유저 스와이프가 아니다 — 관찰을 먼저 끊는다.
        stateObservationTask?.cancel()
        stateObservationTask = nil
        guard let activity else { return }
        self.activity = nil
        // .default: missed/serviceEnded 최종 상태가 잠금화면에 잠깐 남는 것이 정책 취지.
        await activity.end(
            ActivityContent(
                state: Self.contentState(from: state),
                staleDate: state.departureTime
            ),
            dismissalPolicy: .default
        )
    }

    var isDismissedByUser: Bool { dismissedByUser }

    /// Phase 15 폴백 조건 확대 — dismiss 기록 하나로는 "LA를 설정에서 꺼둔 유저"(start가
    /// no-op이라 activity 자체가 없다)와 "시작 실패·시스템 종료 후 재시작도 막힌 세션"이
    /// 전부 인지 채널 0으로 남는다. 세 조건을 어댑터가 한 번에 판정한다 — 호출자
    /// (AlarmSyncService)는 조건을 조립하지 않는다. 죽은 세션 재시작(restartIfNeeded)이
    /// 표출(propagateChange)보다 선행하므로, 재시작에 성공한 세션은 자연히 도달 가능이다.
    var isAlertReachable: Bool {
        activity != nil
            && ActivityAuthorizationInfo().areActivitiesEnabled
            && !dismissedByUser
    }

    // MARK: - LastTrainDepartureEnding (Phase 13)

    /// 정책: departed 상태는 잠금화면에 남았다가 출발 + 10분에 자동 소멸한다(.after) —
    /// "지금 출발" 상태가 잠시 남는 것이 취지. end 이후 남은 시간 창(최대 3분+10분)의
    /// 재변경 인지는 알람 재스케줄(기존 경로)이 담당하고, LA 재생성은 하지 않는다(계약).
    private var departedDismissalGraceSeconds: TimeInterval {
        #if DEV
        // 자동 검수 규약: 자동 소멸 대기가 과도할 때 DEV 한정 단축 —
        // `simctl spawn booted defaults write com.atcha.iOS.v2 dev.la.departedDismissalGrace -int 60`
        let override = userDefaults.double(forKey: "dev.la.departedDismissalGrace")
        if override > 0 { return override }
        #endif
        return 600
    }

    func endAsDeparted() async {
        // 프로그램적 end — 예약 소멸 시점에 도착하는 .dismissed를 유저 스와이프로
        // 오인하지 않도록 관찰을 먼저 끊는다(end(final:)과 동일 순서).
        stateObservationTask?.cancel()
        stateObservationTask = nil
        // 세션 부재(강제 종료 후 고아, LA 비활성 등)는 조용히 no-op —
        // 확인 기록은 이미 남았고, 고아 재부착은 Phase 14 몫이다.
        guard let activity else { return }
        self.activity = nil

        // departed 상태는 현재 콘텐츠의 세션 사실(출발·알람 시각)을 그대로 잇는다 —
        // glance 색은 imminent와 동일 척도(정책), 배지는 접는다.
        let current = activity.content.state
        let departed = LastTrainActivityAttributes.ContentState(
            departureTime: current.departureTime,
            alarmTime: current.alarmTime,
            urgency: .imminent,
            changeBadgeExpiry: nil,
            status: .departed
        )
        await activity.end(
            // staleDate nil: departed는 시각 최신성 경고 대상이 아니다 — 소멸은 .after가 맡는다.
            ActivityContent(state: departed, staleDate: nil),
            dismissalPolicy: .after(
                current.departureTime.addingTimeInterval(departedDismissalGraceSeconds)
            )
        )
    }

    // MARK: - LastTrainChangeAlerting

    func update(state: LastTrainActivityState, alert: (title: String, body: String)?) async {
        guard let activity else { return }
        // staleDate도 매 갱신마다 최신 출발 시각으로 재설정한다(앞당겨짐·미뤄짐 반영).
        let content = ActivityContent(
            state: Self.contentState(from: state),
            staleDate: state.departureTime
        )
        // LocalizedStringResource의 키로 원문을 그대로 쓴다 — 테이블 미등록 키는 원문 표시.
        let alertConfiguration = alert.map {
            AlertConfiguration(
                title: LocalizedStringResource(stringLiteral: $0.title),
                body: LocalizedStringResource(stringLiteral: $0.body),
                sound: .default
            )
        }
        await activity.update(content, alertConfiguration: alertConfiguration)
    }

    // MARK: - Dismiss 감지

    /// 유저가 잠금화면에서 LA를 스와이프로 지우면 `.dismissed`가 도착한다.
    /// 프로그램적 end 경로는 관찰을 먼저 cancel하므로 여기 도달하는 `.dismissed`는 유저 행동뿐이다.
    private func observeActivityState(_ activity: Activity<LastTrainActivityAttributes>) {
        stateObservationTask?.cancel()
        stateObservationTask = Task { [weak self] in
            for await state in activity.activityStateUpdates {
                guard !Task.isCancelled else { return }
                if state == .dismissed {
                    await self?.recordDismissedByUser(true)
                    return
                }
            }
        }
    }

    private func recordDismissedByUser(_ value: Bool) {
        dismissedByUser = value
        userDefaults.set(value, forKey: Self.dismissedDefaultsKey)
    }

    #if DEV
    // MARK: - DEV 검수용 (Phase 12 dismiss 폴백)

    /// 플로팅 디버그 메뉴의 현재값 표시용 — 인메모리 캐시와 UserDefaults는 항상 함께 갱신되므로
    /// MainActor(UI)에서 UserDefaults만 동기로 읽어도 어긋나지 않는다.
    nonisolated static var devDismissedDefaultsKey: String { dismissedDefaultsKey }

    /// 잠금화면 스와이프 자동화가 불안정할 때 dismiss 기록을 강제로 뒤집는 검수 수단.
    /// recordDismissedByUser를 그대로 타므로 인메모리 캐시와 UserDefaults가 함께 갱신된다 —
    /// UserDefaults만 바깥에서 직접 만지면 살아 있는 액터가 낡은 캐시 값을 계속 답하게 된다.
    func devToggleDismissedByUser() -> Bool {
        recordDismissedByUser(!dismissedByUser)
        return dismissedByUser
    }
    #endif

    // MARK: - Domain → CoreLiveActivity 매핑

    /// Domain 상태 → 위젯 계약 ContentState. urgency/phase는 양쪽 enum의 rawValue가 동일하다.
    /// rawValue 불일치는 계약 위반이므로 방어값은 안전한 쪽(imminent/active)으로 둔다.
    private nonisolated static func contentState(
        from state: LastTrainActivityState
    ) -> LastTrainActivityAttributes.ContentState {
        LastTrainActivityAttributes.ContentState(
            departureTime: state.departureTime,
            alarmTime: state.alarmTime,
            urgency: CoreLiveActivity.LastTrainUrgency(rawValue: state.urgency.rawValue)
                ?? .imminent,
            changeBadgeExpiry: state.changeBadgeExpiry,
            status: CoreLiveActivity.LastTrainSessionStatus(rawValue: state.phase.rawValue)
                ?? .active
        )
    }

    /// Domain 수단 → 위젯 계약 수단 키 (Phase 14 DI 아이콘 분기).
    private nonisolated static func transportKind(
        from mode: TransportMode?
    ) -> LastTrainTransportKind? {
        switch mode {
        case .bus: .bus
        case .subway: .subway
        case .walk, .unknown: .other
        case nil: nil
        }
    }
}
