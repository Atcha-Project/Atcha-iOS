import CoreStorage
import Domain
import Foundation
import os

/// 알람 세션을 소유하는 **유일한 지점**. 읽기도 쓰기도 여기를 통한다.
///
/// 이전에는 하나의 세션이 8군데에 복제돼 있었다 — 서버, `lastInfo`(replay 버퍼 겸
/// diff 이전 값 겸 만료 판정 대상), 파생 메모리 5종, 스냅샷, AlarmKit 레코드,
/// AlarmKit, ActivityKit, 그리고 홈 ViewModel 사본. 이 중 OS·원격이 소유한
/// 4개(서버·AlarmKit 레코드·AlarmKit·ActivityKit)는 본질적 미러라 없앨 수 없지만,
/// **앱이 소유한 나머지는 하나로 모을 수 있다.** 이 타입이 그 하나다.
///
/// `@MainActor` 클래스인 이유: `actor`로 만들면 `current`가 `async`가 되어 홈 렌더
/// 경로마다 `await`가 붙는다. 세션 쓰기는 동기화 트리거 4경로에서만 일어나고 그
/// 경로가 이미 `inFlight` 합류로 직렬화되므로, 메인 액터 격리만으로 단일 writer가
/// 보장된다.
@MainActor
final class AlarmSessionStore {
    private static let logger = Logger(subsystem: "com.atcha.alarm", category: "session")

    /// 새 키다 — 기존 `alarm.sessionSnapshot`과 스키마가 다르다. V2가 미출시이므로
    /// 마이그레이션을 두지 않고, 구 키는 전환이 끝난 뒤 정리한다.
    static let storageKey = "alarm.session"

    private let document: DocumentStore<AlarmSession>
    private var subscribers: [UUID: AsyncStream<AlarmSession?>.Continuation] = [:]

    /// 메모리 캐시 = 동기 읽기의 근거. 디스크 로드는 `bootstrap()`에서 1회만 한다.
    private(set) var current: AlarmSession?
    private var didBootstrap = false

    init(store: any KeyValueStore) {
        document = DocumentStore(store: store, key: Self.storageKey)
    }

    /// 앱 시작 직후 1회. **sync보다 먼저 불러야 한다** — 그래야 오프라인 콜드스타트에서도
    /// 홈이 배너·카드를 즉시 그린다. 이전 구조는 시딩 게이트가 `sync()` 안에 있어서
    /// sync가 돌지 않으면 복원도 되지 않았다.
    func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        current = await document.load()
        if let current {
            Self.logger.info(
                """
                세션 복원: route=\(current.server.lastRouteId, privacy: .public) \
                lifecycle=\(current.lifecycle.rawValue, privacy: .public)
                """
            )
        }
        // 톰스톤이어도 방출한다 — 홈이 "지난 막차" 카드를 그릴 근거이고,
        // 무엇보다 구독자가 "아직 로드 전"과 "세션 없음"을 구분할 수 있어야 한다.
        broadcast()
    }

    /// Reconciler 판정을 그대로 반영한다. **세션 상태가 바뀌는 유일한 경로**다.
    func apply(_ outcome: AlarmSessionReconciler.Outcome) async {
        switch outcome {
        case let .refreshed(session):
            await persist(session)

        case let .expired(session):
            // clear가 아니라 톰스톤을 남긴다 — 지워 버리면 다음 실행에서 같은 과거
            // 세션의 refresh가 배너·재부착을 되살린다.
            Self.logger.info(
                "세션 만료 확정: route=\(session.server.lastRouteId, privacy: .public)"
            )
            await persist(session)

        case .ended:
            await clear()

        case .ignoredStaleEcho:
            // 아무것도 하지 않는다. 방출도 하지 않아야 한다 — 같은 값을 다시 흘리면
            // 구독자가 불필요하게 다시 렌더한다.
            break
        }
    }

    /// stopIntent("확인") 수신 — LA 재시작 금지 상태로 전이한다.
    func acknowledge() async {
        guard let session = current, session.lifecycle == .active else { return }
        await persist(session.with(lifecycle: .acknowledged))
    }

    /// 등록 성공 직후. 서버가 주지 않는 로컬 사실(도보 초·표시명·수단)의 유일한 기록
    /// 시점이라, **서버 등록 직후·로컬 스케줄 전에** 불러야 한다. 스케줄이 실패해
    /// 앱이 죽어도 다음 sync가 도보 초를 복원할 수 있다(그러지 않으면 알람이 도보
    /// 시간만큼 늦게 울린다).
    func register(session: AlarmSession) async {
        await persist(session)
    }

    func clear() async {
        try? await document.clear()
        current = nil
        broadcast()
    }

    /// 로그아웃·탈퇴 — 로컬 기록을 비우고 구독자에게도 알린다.
    func reset() async {
        await clear()
    }

    // MARK: - 구독

    /// 구독자마다 독립 스트림. **replay-1** — 구독 전에 끝난 부트스트랩·동기화를
    /// 놓치지 않아야 한다. (변경 *사건*은 replay하지 않는 별도 채널이 맡는다.)
    func updates() -> AsyncStream<AlarmSession?> {
        let id = UUID()
        return AsyncStream { continuation in
            subscribers[id] = continuation
            continuation.yield(current)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in self?.subscribers[id] = nil }
            }
        }
    }

    // MARK: -

    private func persist(_ session: AlarmSession) async {
        // 저장 실패를 흡수하는 이유: 정본은 서버다. 디스크 기록은 재실행 브리지이므로
        // 실패해도 이번 실행의 동작을 막아서는 안 된다(다음 sync가 자가치유).
        try? await document.save(session)
        current = session
        broadcast()
    }

    private func broadcast() {
        for continuation in subscribers.values {
            continuation.yield(current)
        }
    }
}
