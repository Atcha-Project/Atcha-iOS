import Foundation
import Synchronization

/// ViewModel이 들고 있는 비동기 작업들을 키로 관리한다.
///
/// 이전에는 ViewModel마다 `Task` 필드를 나열하고(홈 9개, 검색 5개) `deinit`에서 전부
/// 취소하며, 재진입 방지는 `guard xxxTask == nil else { return }` 같은 수기 가드로
/// 처리했다. 필드를 하나 늘릴 때마다 `deinit`에 한 줄을 잊지 않아야 했고, 어떤 작업이
/// 어떤 재진입 규칙을 따르는지는 주석으로만 남아 있었다.
///
/// `Policy`가 그 규칙을 타입으로 만든다.
/// `Mutex` 기반인 이유: 소유자의 `deinit`에서 일괄 취소할 수 있어야 하는데, `deinit`은
/// nonisolated라 액터 격리된 저장 프로퍼티를 만질 수 없다. 기존 ViewModel들이 `deinit`에
/// Task 취소를 나열하던 자리를 그대로 대체하려면 격리 밖에서도 접근 가능해야 한다.
public nonisolated final class TaskBox<Key: Hashable & Sendable>: @unchecked Sendable {
    /// 같은 키의 작업이 이미 돌고 있을 때 무엇을 할지.
    public nonisolated enum Policy: Sendable {
        /// 기존 작업을 취소하고 새로 시작한다 — 최신 입력만 의미가 있는 조회에 쓴다
        /// (위치 재조회, 키워드 검색).
        case replaceExisting
        /// 기존 작업이 끝날 때까지 새 요청을 무시한다 — 중복 발사가 해로운 동작에 쓴다
        /// (당김 새로고침, 제출).
        case skipIfRunning
        /// 같은 키라도 독립적으로 돌린다 — 저장처럼 "나중 것이 앞 것을 취소하면 안 되는"
        /// 작업에 쓴다. 키는 추적·일괄 취소 목적으로만 쓰인다.
        case independent
    }

    private struct Storage {
        var tasks: [Key: Task<Void, Never>] = [:]
        /// `.independent`로 띄운 작업들 — 키로 덮어쓰지 않고 따로 모은다.
        var detached: [Task<Void, Never>] = []
    }

    private let storage = Mutex(Storage())

    public init() {}

    deinit {
        cancelAll()
    }

    /// 정책에 따라 작업을 시작한다. 시작하지 않은 경우 `false`를 돌려준다.
    @discardableResult
    public func run(
        _ key: Key,
        _ policy: Policy = .replaceExisting,
        _ body: @escaping @Sendable () async -> Void
    ) -> Bool {
        let shouldStart = storage.withLock { storage -> Bool in
            switch policy {
            case .skipIfRunning:
                guard let existing = storage.tasks[key], !existing.isCancelled else { return true }
                return false
            case .replaceExisting:
                storage.tasks[key]?.cancel()
                return true
            case .independent:
                return true
            }
        }
        guard shouldStart else { return false }

        let task = Task { [weak self] in
            await body()
            // 완료된 작업을 남겨 두면 `.skipIfRunning`이 영구히 막힌다 —
            // 이 정리를 잊는 것이 기존 코드에서 실제로 났던 버그다(pull-to-refresh 영구 잠김).
            self?.finish(key, policy: policy)
        }

        storage.withLock { storage in
            if case .independent = policy {
                storage.detached.append(task)
            } else {
                storage.tasks[key] = task
            }
        }
        return true
    }

    public func isRunning(_ key: Key) -> Bool {
        storage.withLock { storage in
            guard let task = storage.tasks[key] else { return false }
            return !task.isCancelled
        }
    }

    public func cancel(_ key: Key) {
        storage.withLock { $0.tasks.removeValue(forKey: key) }?.cancel()
    }

    /// 소유자 해제·로그아웃 등에서 부른다. `deinit`에서도 안전하다.
    public func cancelAll() {
        let (tasks, detached) = storage.withLock { storage -> ([Task<Void, Never>], [Task<Void, Never>]) in
            let result = (Array(storage.tasks.values), storage.detached)
            storage.tasks.removeAll()
            storage.detached.removeAll()
            return result
        }
        for task in tasks { task.cancel() }
        for task in detached { task.cancel() }
    }

    private func finish(_ key: Key, policy: Policy) {
        storage.withLock { storage in
            if case .independent = policy {
                storage.detached.removeAll { $0.isCancelled }
            } else {
                storage.tasks[key] = nil
            }
        }
    }
}
