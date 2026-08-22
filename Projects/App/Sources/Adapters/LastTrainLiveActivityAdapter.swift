@preconcurrency import ActivityKit
import CoreLiveActivity
import Domain
import Foundation

/// ActivityKit → Domain `LastTrainActivityPort` 어댑터. ActivityKit을 import하는 곳은 App에서 이 파일뿐.
/// 단일 알람 정책과 동일하게 Live Activity도 단일 세션만 유지한다(새 start가 기존 세션을 교체).
/// 포트 계약대로 어떤 실패도 밖으로 던지지 않는다 — LA 실패가 알람 등록·취소를 실패시키면 안 된다.
///
/// actor인 이유: 포트는 nonisolated async 요구사항을 가진 Sendable 프로토콜이라
/// MainActor 클래스의 격리 멤버로는 적합성이 성립하지 않는다(Sendable 경계를 넘는 격리 적합성 불가).
/// ActivityKit의 `Activity`는 Sendable 미표기이나 스레드 안전 설계라 `@preconcurrency`로 완화한다.
actor LastTrainLiveActivityAdapter: LastTrainActivityPort {
    /// 유저 스와이프 dismiss 기록 키 — 앱 재실행 후에도 남아야 Phase 12 폴백 트리거 재료가 된다.
    private static let dismissedDefaultsKey = "la.dismissedByUser"

    // TODO: Phase 11 — 변경 유형별 알림 문구를 UseCase에서 주입한다. 그 전까지는 범용 문구.
    private static let alertTitle: LocalizedStringResource = "막차 정보가 변경됐어요"
    private static let alertBody: LocalizedStringResource = "잠금화면에서 최신 막차 시간을 확인하세요"

    private let userDefaults: UserDefaults

    /// 단일 세션 — 단일 알람 정책과 동일. 새 start가 이전 activity를 먼저 내린다.
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
        let initialState = LastTrainActivityState(
            departureTime: departureTime,
            // TODO: Phase 11 — 알람 버퍼(기준 시각 − 버퍼) 도입 전까지 alarmTime = departureTime.
            alarmTime: departureTime,
            urgency: Domain.LastTrainUrgency.forTimeRemaining(
                departureTime.timeIntervalSinceNow
            ),
            changeBadgeExpiry: nil,
            phase: .active
        )

        do {
            let requested = try Activity.request(
                attributes: LastTrainActivityAttributes(
                    routeId: route.id,
                    routeName: Self.displayRouteName(for: route)
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

    func update(state: LastTrainActivityState, alert: Bool) async {
        guard let activity else { return }
        // staleDate도 매 갱신마다 최신 출발 시각으로 재설정한다(앞당겨짐·미뤄짐 반영).
        let content = ActivityContent(
            state: Self.contentState(from: state),
            staleDate: state.departureTime
        )
        let alertConfiguration: AlertConfiguration? = alert
            ? AlertConfiguration(title: Self.alertTitle, body: Self.alertBody, sound: .default)
            : nil
        await activity.update(content, alertConfiguration: alertConfiguration)
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

    /// 노선 표시명 — 막차 탑승 구간(departureTime이 있는 첫 대중교통 구간, 없으면 첫 대중교통 구간) 기준.
    /// 버스 routeName은 "타입:번호"(예: "간선:472") → "472번 버스", 지하철은 노선명 그대로(급행이면 " 급행").
    private nonisolated static func displayRouteName(for route: LastRoute) -> String {
        let transitLegs = route.legs.filter { $0.mode == .bus || $0.mode == .subway }
        guard let leg = transitLegs.first(where: { $0.departureTime != nil }) ?? transitLegs.first
        else { return "막차" }

        switch leg.mode {
        case .subway:
            guard let name = leg.routeName else { return "지하철" }
            return leg.isExpressSubway ? "\(name) 급행" : name
        case .bus:
            guard let routeName = leg.routeName else { return "버스" }
            guard let colonIndex = routeName.firstIndex(of: ":") else {
                return "\(routeName)번 버스"
            }
            let number = String(routeName[routeName.index(after: colonIndex)...])
            return "\(number)번 버스"
        case .walk, .unknown:
            return "막차"
        }
    }
}
