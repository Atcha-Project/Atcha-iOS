import CoreNetwork
import Foundation

/// 스플래시 부트스트랩 실패 문구 매핑(Phase 16) — 원인 불문 고정 문구를 오프라인/기타로
/// 나눈다. 순수 함수라 AtchaV2Tests가 직접 검증한다. 실패 경로는 토큰이 없을 때의
/// 게스트 세션 발급(스플래시 재시도 UI)이다.
enum BootstrapFailureMessage {
    static let offline = "네트워크 연결을 확인해주세요"
    static let transient = "일시적인 문제가 생겼어요. 잠시 후 다시 시도해주세요"

    static func text(for error: any Error) -> String {
        (error as? NetworkError)?.isOffline == true ? offline : transient
    }
}
