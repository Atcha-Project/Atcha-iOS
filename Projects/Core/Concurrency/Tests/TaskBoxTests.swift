@testable import CoreConcurrency
import Foundation
import Synchronization
import Testing

private nonisolated final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() { lock.lock(); value += 1; lock.unlock() }
    func get() -> Int { lock.lock(); defer { lock.unlock() }; return value }
}

/// 모듈 기본 격리가 `.mainActor`라, 명시하지 않으면 `Hashable` 적합성까지 메인 액터
/// 격리를 얻어 `TaskBox`의 `Sendable` 제약을 만족하지 못한다.
private nonisolated enum Key: Hashable, Sendable { case load, save, refresh }

struct TaskBoxTests {

    // MARK: - replaceExisting

    /// 최신 입력만 의미가 있는 조회 — 새 요청이 이전 것을 취소한다.
    @Test
    func replaceExisting_cancelsPrevious() async {
        let box = TaskBox<Key>()
        let firstCancelled = Counter()

        box.run(.load, .replaceExisting) {
            try? await Task.sleep(for: .milliseconds(200))
            if Task.isCancelled { firstCancelled.increment() }
        }
        box.run(.load, .replaceExisting) {}

        try? await Task.sleep(for: .milliseconds(50))
        #expect(firstCancelled.get() == 1)
    }

    // MARK: - skipIfRunning

    /// 중복 발사가 해로운 동작 — 진행 중이면 새 요청을 무시한다.
    @Test
    func skipIfRunning_ignoresWhileRunning() async {
        let box = TaskBox<Key>()
        let started = Counter()

        box.run(.refresh, .skipIfRunning) {
            started.increment()
            try? await Task.sleep(for: .milliseconds(100))
        }
        // Task는 생성 즉시 실행되지 않는다 — 첫 작업이 시작될 때까지 양보한다.
        while started.get() == 0 { await Task.yield() }

        let secondStarted = box.run(.refresh, .skipIfRunning) { started.increment() }

        #expect(secondStarted == false)
        #expect(started.get() == 1)
    }

    /// 회귀: 완료된 작업을 정리하지 않으면 `.skipIfRunning`이 **영구히 막힌다.**
    /// 기존 코드에서 실제로 났던 버그다(당김 새로고침이 취소 후 영원히 잠김).
    @Test
    func skipIfRunning_allowsNewRunAfterCompletion() async {
        let box = TaskBox<Key>()
        let started = Counter()

        box.run(.refresh, .skipIfRunning) { started.increment() }
        while box.isRunning(.refresh) { await Task.yield() }

        let secondStarted = box.run(.refresh, .skipIfRunning) { started.increment() }
        while box.isRunning(.refresh) { await Task.yield() }

        #expect(secondStarted == true)
        #expect(started.get() == 2)
    }

    /// 취소된 작업도 키를 붙잡고 있으면 안 된다.
    @Test
    func skipIfRunning_allowsNewRunAfterCancel() async {
        let box = TaskBox<Key>()
        box.run(.refresh, .skipIfRunning) { try? await Task.sleep(for: .seconds(10)) }

        box.cancel(.refresh)

        #expect(box.run(.refresh, .skipIfRunning) {} == true)
    }

    // MARK: - independent

    /// 저장은 나중 것이 앞 것을 취소하면 안 된다 — 둘 다 끝까지 간다.
    @Test
    func independent_runsConcurrentlyWithoutCancelling() async {
        let box = TaskBox<Key>()
        let completed = Counter()

        for _ in 0..<3 {
            box.run(.save, .independent) {
                try? await Task.sleep(for: .milliseconds(20))
                guard !Task.isCancelled else { return }
                completed.increment()
            }
        }
        try? await Task.sleep(for: .milliseconds(120))

        #expect(completed.get() == 3)
    }

    // MARK: - 정리

    @Test
    func cancelAll_stopsEverything() async {
        let box = TaskBox<Key>()
        let finished = Counter()

        // `try?`가 취소를 삼키므로 취소 여부를 명시적으로 확인해야 한다 —
        // 그러지 않으면 sleep 이후 코드가 그대로 실행된다.
        box.run(.load) {
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            finished.increment()
        }
        box.run(.save, .independent) {
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            finished.increment()
        }
        while !box.isRunning(.load) { await Task.yield() }

        box.cancelAll()
        try? await Task.sleep(for: .milliseconds(50))

        #expect(finished.get() == 0)
        #expect(box.isRunning(.load) == false)
    }

    @Test
    func cancel_affectsOnlyGivenKey() async {
        let box = TaskBox<Key>()
        box.run(.load) { try? await Task.sleep(for: .seconds(10)) }
        box.run(.refresh) { try? await Task.sleep(for: .seconds(10)) }

        box.cancel(.load)

        #expect(box.isRunning(.load) == false)
        #expect(box.isRunning(.refresh) == true)
        box.cancelAll()
    }
}
