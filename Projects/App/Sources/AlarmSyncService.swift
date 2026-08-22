import Domain
import Foundation
import UIKit
import os

/// 서버발 알람 시각 갱신의 단일 진입점. 앱 시작(인증 부트스트랩 직후)·포그라운드
/// 복귀·사일런트 푸시 3경로가 전부 여기의 `RefreshAlarmUseCase` 호출 한 곳으로
/// 모인다 — 시각 변경 시 재스케줄은 UseCase 내부 정책이고, 성공 결과는
/// `AlarmSyncEvents` 스트림으로 구독자(HomeViewModel)에게 전파돼 배너를 갱신한다.
///
/// Phase 11 피기백: 갱신 성공 뒤 전/후 AlarmInfo를 판정(`EvaluateAlarmChangeUseCase`)해
/// ① LA 채널(당겨짐 alert / 늦춰짐 조용한 갱신)과 ② 인앱 채널(`AlarmChangeEvents` →
/// 홈 배너 강조·토스트)을 덧붙인다. 알람 재스케줄은 `RefreshAlarmUseCase.execute()` 안에서
/// 이미 끝난 뒤라(반환 = 재스케줄 완료) LA·인앱 표출 실패가 알람을 막을 구조 자체가 없다.
// Sendable 프로토콜(AlarmSyncEvents 등) 채택이 기본 MainActor 격리를 nonisolated로
// 추론시키므로 명시한다 — 상태(subscribers 등)는 전부 메인 액터에서만 만진다.
@MainActor
final class AlarmSyncService: AlarmSyncEvents, AlarmChangeEvents {
    private let refreshAlarmUseCase: any RefreshAlarmUseCase
    private let evaluateChangeUseCase: any EvaluateAlarmChangeUseCase
    /// LA 표출 경로 — non-throwing 계약(어댑터가 실패 흡수)이라 이 훅의 어떤 실패도 무해하다.
    private let liveActivity: any LastTrainChangeAlerting
    private static let logger = Logger(subsystem: "com.atcha.iOS.v2", category: "AlarmSync")

    /// "⚠ 당겨짐" 배지 유지 시간 — 정책: 표출 시점 + 10분.
    private static let changeBadgeDuration: TimeInterval = 600

    private var subscribers: [UUID: AsyncStream<AlarmInfo>.Continuation] = [:]
    /// 변경 판정 구독자 — updates()와 달리 **replay 없음**(과거 변경이 재구독 시 재발화 금지).
    private var changeSubscribers: [UUID: AsyncStream<AlarmChangeVerdict>.Continuation] = [:]
    /// 구독 전에 끝난 동기화를 놓치지 않기 위한 replay-1. 홈은 앱 시작 동기화와
    /// 거의 동시에 구독하므로 순서에 기대지 않는다. 변경 판정의 "이전 값"이기도 하다.
    private var lastInfo: AlarmInfo?
    /// 진행 중 동기화 — 트리거가 겹치면(예: 앱 시작 직후 포그라운드 노티) 합류한다.
    private var inFlight: Task<AlarmInfo?, Never>?
    private var foregroundObserver: (any NSObjectProtocol)?

    // 앱 수명 객체(조합 루트 소유) — 해제 경로가 없어 관찰 해지/태스크 취소 정리가 없다.
    init(
        refreshAlarmUseCase: any RefreshAlarmUseCase,
        evaluateChangeUseCase: any EvaluateAlarmChangeUseCase,
        liveActivity: any LastTrainChangeAlerting
    ) {
        self.refreshAlarmUseCase = refreshAlarmUseCase
        self.evaluateChangeUseCase = evaluateChangeUseCase
        self.liveActivity = liveActivity
    }

    /// 인증 부트스트랩 완료 후 1회 호출: 즉시 동기화(앱 시작 경로) + 포그라운드
    /// 관찰 시작. 그 전의 포그라운드 전환은 무시된다 — 세션 없이 refresh를 쏘지 않는다.
    func activate() {
        guard foregroundObserver == nil else { return }
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIScene.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Sendable 클로저 → 메인 액터 복귀. 서비스는 앱과 수명이 같아 강한 캡처로 충분하다.
            Task { @MainActor in _ = await self.sync() }
        }
        Task { _ = await sync() }
    }

    /// 사일런트 푸시(content-available=1) 경로 — 백그라운드 fetch 결과 매핑까지 담당.
    func syncFromPush() async -> UIBackgroundFetchResult {
        await sync() != nil ? .newData : .failed
    }

    /// 3경로 공용 동기화. 실패는 스트림에 흘리지 않는다 — 구독자는 상태를 유지하고,
    /// 다음 트리거(포그라운드·푸시)가 자연 재시도가 된다.
    @discardableResult
    private func sync() async -> AlarmInfo? {
        if let inFlight {
            return await inFlight.value
        }
        Self.logger.info("알람 동기화 시작")
        let task = Task { [refreshAlarmUseCase] () -> AlarmInfo? in
            do {
                return try await refreshAlarmUseCase.execute()
            } catch {
                Self.logger.info("알람 동기화 실패(상태 유지): \(error)")
                return nil
            }
        }
        inFlight = task
        let info = await task.value
        inFlight = nil
        if let info {
            Self.logger.info("알람 동기화 성공: route=\(info.lastRouteId, privacy: .public)")
            let previous = lastInfo
            lastInfo = info
            for continuation in subscribers.values {
                continuation.yield(info)
            }
            // Phase 11 피기백 — 이 시점에 알람 재스케줄은 이미 완료돼 있다
            // (RefreshAlarmUseCase.execute 반환 = 재스케줄 포함). 표출은 그 뒤에만 덧붙는다.
            await propagateChange(previous: previous, latest: info)
        }
        return info
    }

    // MARK: - Phase 11 변경 표출 (판정 → LA/인앱 채널)

    /// 판정 → 채널 분기. LA 호출은 전부 실패 무해(포트가 non-throwing) — 알람에 영향 없음.
    private func propagateChange(previous: AlarmInfo?, latest: AlarmInfo) async {
        let now = Date()
        // 첫 수신(이전 값 없음)은 비교 대상이 없다 — unchanged 취급.
        let verdict = previous.map {
            evaluateChangeUseCase.execute(previous: $0, latest: latest, now: now)
        } ?? AlarmChangeVerdict.unchanged

        switch verdict {
        case .unchanged:
            // 변경 없음 — 조용한 상태 갱신 1회만(긴급도 색 재평가 목적). 배지·alert·yield 없음.
            if let state = activityState(for: latest, now: now) {
                await liveActivity.update(state: state, alert: nil)
            }

        case .delayed:
            // 늦춰짐 — 새 시각·재평가 긴급도로 조용한 업데이트. 배지 없음.
            if let state = activityState(for: latest, now: now) {
                await liveActivity.update(state: state, alert: nil)
            }
            yieldChange(verdict)

        case let .advanced(by: delta, actionable: true):
            await presentAdvanced(previous: previous, latest: latest, delta: delta, now: now)
            yieldChange(verdict)

        case .advanced(by: _, actionable: false), .sessionEnded:
            // TODO(Phase 12): 못 탐/운행 종료 표출(missed·serviceEnded 전환, 로컬 노티 폴백)은
            //                 다음 페이즈 산출물 — 그 전까지 조용한 LA 갱신만 한다
            //                 (sessionEnded는 departureTime이 없어 사실상 no-op).
            if let state = activityState(for: latest, now: now) {
                await liveActivity.update(state: state, alert: nil)
            }
            yieldChange(verdict)
        }
    }

    /// 앞당겨짐(actionable) 표출 — 새 알람 시각과 앱 상태로 alert 채널을 고른다.
    private func presentAdvanced(
        previous: AlarmInfo?,
        latest: AlarmInfo,
        delta: TimeInterval,
        now: Date
    ) async {
        guard let departure = latest.departureTime else { return }
        let alarmTime = AlarmTiming.alarmFireDate(departureTime: departure)
        let badgeExpiry = now.addingTimeInterval(Self.changeBadgeDuration)

        guard alarmTime > now else {
            // 새 알람 시각이 이미 과거(출발은 미래) — 마지노선 침범. 원래 울렸어야 할 알람
            // 시점이 지나 있으므로 조용한 채널로는 늦다: 포그라운드 여부와 무관하게 즉시 최후통첩.
            let state = LastTrainActivityState(
                departureTime: departure,
                alarmTime: alarmTime,
                urgency: .imminent,
                changeBadgeExpiry: badgeExpiry,
                phase: .active
            )
            await liveActivity.update(state: state, alert: (
                title: LastTrainChangeMessages.ultimatumTitle,
                body: LastTrainChangeMessages.ultimatumBody(latestDeparture: departure)
            ))
            return
        }

        let state = LastTrainActivityState(
            departureTime: departure,
            alarmTime: alarmTime,
            urgency: LastTrainUrgency.forTimeRemaining(alarmTime.timeIntervalSince(now)),
            changeBadgeExpiry: badgeExpiry,
            phase: .active
        )
        if UIApplication.shared.applicationState == .active {
            // 포그라운드 — LA alert 생략(조용한 업데이트 + 배지). 사용자 주의는 인앱 채널
            // (changes 스트림 → 홈 배너 강조 + 토스트)이 맡는다. 이중 알림 방지.
            await liveActivity.update(state: state, alert: nil)
        } else {
            // 백그라운드 — 잠금화면 alert + 행동 중심 문구 + "당겨짐" 배지(만료 now+10분).
            let minutesEarlier = max(1, Int((delta / 60).rounded(.up)))
            // advanced(by:)의 delta = 이전 출발 − 새 출발. 이전 값이 비어 있으면 새 시각 + delta로 복원.
            let previousDeparture = previous?.departureTime ?? departure.addingTimeInterval(delta)
            await liveActivity.update(state: state, alert: (
                title: LastTrainChangeMessages.advancedAlertTitle(minutesEarlier: minutesEarlier),
                body: LastTrainChangeMessages.advancedAlertBody(from: previousDeparture, to: departure)
            ))
        }
    }

    /// 갱신된 AlarmInfo → LA 상태. departureTime이 없으면(세션 종료 등) 만들 수 없다.
    private func activityState(for info: AlarmInfo, now: Date) -> LastTrainActivityState? {
        guard let departure = info.departureTime else { return nil }
        let alarmTime = AlarmTiming.alarmFireDate(departureTime: departure)
        return LastTrainActivityState(
            departureTime: departure,
            alarmTime: alarmTime,
            urgency: LastTrainUrgency.forTimeRemaining(alarmTime.timeIntervalSince(now)),
            changeBadgeExpiry: nil,
            phase: .active
        )
    }

    private func yieldChange(_ verdict: AlarmChangeVerdict) {
        for continuation in changeSubscribers.values {
            continuation.yield(verdict)
        }
    }

    // MARK: - AlarmSyncEvents

    nonisolated func updates() -> AsyncStream<AlarmInfo> {
        AsyncStream { continuation in
            let id = UUID()
            Task { @MainActor in
                if let last = self.lastInfo {
                    continuation.yield(last)
                }
                self.subscribers[id] = continuation
            }
            continuation.onTermination = { _ in
                Task { @MainActor in
                    self.subscribers.removeValue(forKey: id)
                }
            }
        }
    }

    // MARK: - AlarmChangeEvents

    /// updates()와 달리 replay 없음 — 변경 알림은 상태가 아니라 사건이라,
    /// 재구독 시 과거 판정이 다시 발화하면(배너 강조·토스트 반복) 안 된다.
    nonisolated func changes() -> AsyncStream<AlarmChangeVerdict> {
        AsyncStream { continuation in
            let id = UUID()
            Task { @MainActor in
                self.changeSubscribers[id] = continuation
            }
            continuation.onTermination = { _ in
                Task { @MainActor in
                    self.changeSubscribers.removeValue(forKey: id)
                }
            }
        }
    }
}
