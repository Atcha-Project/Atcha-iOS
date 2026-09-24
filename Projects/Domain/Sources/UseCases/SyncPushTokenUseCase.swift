import Synchronization

public protocol SyncPushTokenUseCase: Sendable {
    /// 로그인 상태에서만 호출할 것 — 토큰 갱신 콜백·로그인 직후 두 지점.
    func execute(token: String) async
    /// 로그아웃 시 호출 — 다음 계정에는 같은 토큰이라도 다시 보내야 한다.
    func reset()
}

public final class DefaultSyncPushTokenUseCase: SyncPushTokenUseCase {
    private let repository: any PushTokenRepository
    /// 프로세스 내 중복 전송 방지 — Firebase는 실행마다 같은 토큰을 다시 알려 준다.
    /// 영속 dedup은 두지 않는다: 실행당 1요청이라 저장소를 늘릴 이유가 없다.
    private let lastSent = Mutex<String?>(nil)

    public init(repository: any PushTokenRepository) {
        self.repository = repository
    }

    public func execute(token: String) async {
        guard lastSent.withLock({ $0 }) != token else { return }
        do {
            try await repository.register(token: token)
            lastSent.withLock { $0 = token }
        } catch {
            // 실패는 삼킨다 — 다음 트리거(재실행·재로그인)가 자연 재시도다.
        }
    }

    public func reset() {
        lastSent.withLock { $0 = nil }
    }
}
