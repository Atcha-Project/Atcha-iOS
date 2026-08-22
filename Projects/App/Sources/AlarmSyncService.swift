import Domain
import Foundation
import UIKit
import os

/// 서버발 알람 시각 갱신의 단일 진입점. 앱 시작(인증 부트스트랩 직후)·포그라운드
/// 복귀·사일런트 푸시 3경로가 전부 여기의 `RefreshAlarmUseCase` 호출 한 곳으로
/// 모인다 — 시각 변경 시 재스케줄은 UseCase 내부 정책이고, 성공 결과는
/// `AlarmSyncEvents` 스트림으로 구독자(HomeViewModel)에게 전파돼 배너를 갱신한다.
// Sendable 프로토콜(AlarmSyncEvents) 채택이 기본 MainActor 격리를 nonisolated로
// 추론시키므로 명시한다 — 상태(subscribers 등)는 전부 메인 액터에서만 만진다.
@MainActor
final class AlarmSyncService: AlarmSyncEvents {
    private let refreshAlarmUseCase: any RefreshAlarmUseCase
    private static let logger = Logger(subsystem: "com.atcha.iOS.v2", category: "AlarmSync")

    private var subscribers: [UUID: AsyncStream<AlarmInfo>.Continuation] = [:]
    /// 구독 전에 끝난 동기화를 놓치지 않기 위한 replay-1. 홈은 앱 시작 동기화와
    /// 거의 동시에 구독하므로 순서에 기대지 않는다.
    private var lastInfo: AlarmInfo?
    /// 진행 중 동기화 — 트리거가 겹치면(예: 앱 시작 직후 포그라운드 노티) 합류한다.
    private var inFlight: Task<AlarmInfo?, Never>?
    private var foregroundObserver: (any NSObjectProtocol)?

    // 앱 수명 객체(조합 루트 소유) — 해제 경로가 없어 관찰 해지/태스크 취소 정리가 없다.
    init(refreshAlarmUseCase: any RefreshAlarmUseCase) {
        self.refreshAlarmUseCase = refreshAlarmUseCase
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
            lastInfo = info
            for continuation in subscribers.values {
                continuation.yield(info)
            }
        }
        return info
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
}
