import CoreLocation
import Domain
import os

/// CoreLocation → Domain `LocationService` 어댑터. CoreLocation을 아는 곳은 여기뿐.
///
/// `CLLocationUpdate.liveUpdates()`는 권한이 notDetermined이면 WhenInUse 요청을
/// 스스로 띄우므로(plist 키 필요) delegate/continuation 없이 one-shot 조회가 된다.
/// App 모듈 기본 격리가 MainActor라 이 클래스는 암시적 Sendable — 프로토콜의
/// nonisolated async 요구사항은 격리 witness로 충족된다.
final class CoreLocationServiceAdapter: LocationService {
    /// **이 로그가 있는 이유.** 위치가 안 잡히는 증상은 원인이 여럿인데(권한 미결정 대기 /
    /// 거부 / 전역 OFF / 스트림 조기 종료) 밖에서는 전부 "출발지가 비어 있다"로만 보인다.
    /// 자동 검수 규약도 이 상황을 *"증상이 '위치가 조용히 안 잡힘'으로 보여 원인 추적이
    /// 어렵다"* 고 적어 뒀다. 업데이트 한 건마다 플래그를 남기면 그 구분이 로그에서 끝난다.
    /// 좌표는 남기지 않는다 — 위치는 민감 정보다.
    private static let logger = Logger(subsystem: "com.atcha.iOS.v2", category: "Location")

    /// CLLocationUpdate의 거부 플래그 3종 → LocationError 매핑(Phase 17). nil = 진행 중.
    /// 우선순위: restricted > 전역 OFF > 앱 권한 거부 — 더 좁은 회복 경로가 이긴다
    /// (restricted는 설정으로 못 풀고, 전역 OFF는 앱 권한 상태를 무의미하게 만든다).
    static func classify(denied: Bool, deniedGlobally: Bool, restricted: Bool) -> LocationError? {
        if restricted { return .restricted }
        if deniedGlobally { return .servicesDisabled }
        if denied { return .permissionDenied }
        return nil
    }

    func currentLocation() async throws -> Coordinate {
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                Self.logger.debug(
                    """
                    update: location=\(update.location != nil, privacy: .public) \
                    denied=\(update.authorizationDenied, privacy: .public) \
                    global=\(update.authorizationDeniedGlobally, privacy: .public) \
                    restricted=\(update.authorizationRestricted, privacy: .public)
                    """
                )
                if let error = Self.classify(
                    denied: update.authorizationDenied,
                    deniedGlobally: update.authorizationDeniedGlobally,
                    restricted: update.authorizationRestricted
                ) {
                    throw error
                }
                if let location = update.location {
                    return Coordinate(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                }
                // 권한 요청 진행 중 / 일시적 위치 불가 → 다음 업데이트를 기다린다.
            }
        } catch let error as LocationError {
            Self.logger.debug("거부·제약으로 종료: \(String(describing: error), privacy: .public)")
            throw error
        } catch {
            Self.logger.debug("스트림 오류로 종료")
            throw LocationError.unavailable
        }
        // 스트림이 위치 없이 끝났다 — 자동 검수 규약이 기록한 "Allow Once로 오염된 상태"가
        // 이 경로다. 어느 쪽인지는 위 업데이트 로그가 말해 준다.
        Self.logger.debug("스트림이 위치 없이 종료")
        throw LocationError.unavailable
    }
}
