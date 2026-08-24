import AlarmKit
import AppIntents
import Foundation
import SwiftUI

/// AlarmKit을 직접 만지는 유일한 타입 — 레포 규칙(AlarmKit import는 CoreAlarm 한정)을
/// 모듈 안에서도 이 파일 한 곳으로 좁힌다. 테스트는 `AlarmEngine` 스텁으로 대체.
struct AlarmKitEngine: AlarmEngine {
    /// 커스텀 Live Activity 없이 기본 알람 UI만 쓰므로 메타데이터는 비어 있다.
    private struct EmptyMetadata: AlarmMetadata {}

    func requestAuthorization() async throws -> Bool {
        switch AlarmManager.shared.authorizationState {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            return try await AlarmManager.shared.requestAuthorization() == .authorized
        @unknown default:
            return false
        }
    }

    func schedule(
        id: UUID, fireDate: Date, title: String, stopIntent: (any LiveActivityIntent)?
    ) async throws {
        // Alert의 non-deprecated init은 iOS 26.1+라 배포 타겟 26.0에서는 stopButton
        // 버전을 쓴다 (26.1 미만 타겟에서는 deprecation 경고가 나지 않는다).
        // 반복(스누즈) 버튼은 넣지 않는다 — "마지노선까지만 미루기" 클램프 검증(Phase 11)
        // 전까지는 단발 알람이 보수 기본값이다.
        // secondaryButton("경로 보기")도 붙이지 않는다 — 심야 버튼 2개는 인지 부하(제품 결정).
        let alert = AlarmPresentation.Alert(
            title: "\(title)",
            stopButton: AlarmButton(text: "확인", textColor: .white, systemImageName: "checkmark")
        )
        // CoreAlarm은 무의존 모듈이라 DesignSystem 토큰을 볼 수 없다 — 시스템 기본 틴트 사용.
        let attributes = AlarmAttributes<EmptyMetadata>(
            presentation: AlarmPresentation(alert: alert),
            tintColor: .accentColor
        )
        // stopIntent: stop("확인") 탭 시 앱 프로세스에서 실행되는 LiveActivityIntent —
        // iOS 26 SDK 실검증 결과 .alarm 팩토리가 stopIntent 파라미터를 직접 받는다.
        _ = try await AlarmManager.shared.schedule(
            id: id,
            configuration: .alarm(
                schedule: .fixed(fireDate),
                attributes: attributes,
                stopIntent: stopIntent
            )
        )
    }

    func cancel(id: UUID) async {
        // 이미 사라진 알람의 취소 실패는 무시한다 (교체·정리 경로를 막지 않는다).
        try? AlarmManager.shared.cancel(id: id)
    }

    func alarmIDs() async -> [UUID] {
        (try? AlarmManager.shared.alarms.map(\.id)) ?? []
    }
}
