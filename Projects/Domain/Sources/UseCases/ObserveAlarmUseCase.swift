import Foundation

public protocol ObserveAlarmUseCase: Sendable {
    func execute() -> AsyncStream<AlarmInfo>
}

public struct DefaultObserveAlarmUseCase: ObserveAlarmUseCase {
    private let events: any AlarmSyncEvents

    public init(events: any AlarmSyncEvents) {
        self.events = events
    }

    public func execute() -> AsyncStream<AlarmInfo> {
        events.updates()
    }
}
