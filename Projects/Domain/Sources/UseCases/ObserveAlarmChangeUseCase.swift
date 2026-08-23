import Foundation

public protocol ObserveAlarmChangeUseCase: Sendable {
    func execute() -> AsyncStream<AlarmChangeVerdict>
}

public struct DefaultObserveAlarmChangeUseCase: ObserveAlarmChangeUseCase {
    private let events: any AlarmChangeEvents

    public init(events: any AlarmChangeEvents) {
        self.events = events
    }

    public func execute() -> AsyncStream<AlarmChangeVerdict> {
        events.changes()
    }
}
