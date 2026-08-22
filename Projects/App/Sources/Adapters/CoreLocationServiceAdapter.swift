import CoreLocation
import Domain

/// CoreLocation → Domain `LocationService` 어댑터. CoreLocation을 아는 곳은 여기뿐.
///
/// `CLLocationUpdate.liveUpdates()`는 권한이 notDetermined이면 WhenInUse 요청을
/// 스스로 띄우므로(plist 키 필요) delegate/continuation 없이 one-shot 조회가 된다.
/// App 모듈 기본 격리가 MainActor라 이 클래스는 암시적 Sendable — 프로토콜의
/// nonisolated async 요구사항은 격리 witness로 충족된다.
final class CoreLocationServiceAdapter: LocationService {
    func currentLocation() async throws -> Coordinate {
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if update.authorizationDenied
                    || update.authorizationDeniedGlobally
                    || update.authorizationRestricted {
                    throw LocationError.permissionDenied
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
            throw error
        } catch {
            throw LocationError.unavailable
        }
        throw LocationError.unavailable
    }
}
