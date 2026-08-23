@testable import AtchaV2
import CoreNetwork
import Foundation
import Testing

private struct SomeError: Error {}

struct BootstrapFailureMessageTests {
    @Test
    func offlineNetworkError_mapsToConnectivityMessage() {
        let error = NetworkError.offline(underlying: URLError(.notConnectedToInternet))
        #expect(BootstrapFailureMessage.text(for: error) == BootstrapFailureMessage.offline)
    }

    @Test
    func otherFailures_mapToTransientMessage() {
        // 타임아웃·서버 오류·비네트워크 에러 전부 "일시적인 문제" — 오프라인만 구분한다.
        #expect(BootstrapFailureMessage.text(
            for: NetworkError.transport(underlying: URLError(.timedOut))
        ) == BootstrapFailureMessage.transient)
        #expect(BootstrapFailureMessage.text(
            for: NetworkError.unacceptableStatus(code: 500, data: Data())
        ) == BootstrapFailureMessage.transient)
        #expect(BootstrapFailureMessage.text(for: SomeError()) == BootstrapFailureMessage.transient)
    }
}
