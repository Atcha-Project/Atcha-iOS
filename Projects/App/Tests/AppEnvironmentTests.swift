@testable import AtchaV2
import Foundation
import Testing

struct AppEnvironmentTests {
    /// 회귀 방지: base에 `/api`가 빠지면 모든 요청이 서버 경로와 어긋난다(2026-09 실사고).
    @Test(arguments: [AppEnvironment.dev, .stage, .live])
    func apiBaseURL_endsWithApiPrefix(environment: AppEnvironment) {
        #expect(environment.apiBaseURL.path == "/api")
    }

    /// URLSessionNetworkClient의 조립 방식(appendingPathComponent)과 같은 결과를 고정한다.
    @Test
    func apiBaseURL_composesServerPaths() {
        let url = AppEnvironment.dev.apiBaseURL.appendingPathComponent("/auth/guest")
        #expect(url.absoluteString == "https://atcha.p-e.kr/api/auth/guest")
    }
}
