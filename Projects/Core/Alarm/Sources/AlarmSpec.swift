import Foundation

/// 디바이스 알람 한 건의 중립 표현 — AlarmKit 타입을 모듈 밖으로 내보내지 않는다.
public struct AlarmSpec: Sendable, Equatable {
    public let id: String
    public let fireDate: Date
    public let title: String

    public init(id: String, fireDate: Date, title: String) {
        self.id = id
        self.fireDate = fireDate
        self.title = title
    }
}
