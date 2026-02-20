//
//  AmplitudeManager.swift
//  Atcha-iOS
//
//  Created by wodnd on 10/16/25.
//

import Foundation
import AmplitudeSwift
import UIKit

// MARK: - Manager
final class AmplitudeManager {
    static let shared = AmplitudeManager()
    private init() {}

    private let queue = DispatchQueue(label: "amp.manager.queue")
    private var client: Amplitude?

    private var timers: [String: Date] = [:]

    // MARK: Public API

    func start(
        userId: Int? = nil,
        autocapture: AutocaptureOptions = [.sessions, .appLifecycles],
        logLevel: LogLevelEnum = .WARN
    ) {
        // 빌드 환경(xcconfig)이 이미 AMPLITUDE_API_KEY를 주입하므로 여기서는 하나만 읽는다
        let apiKey = Self.readApiKey()
        guard let apiKey, !apiKey.isEmpty else {
            assertionFailure("[AmplitudeManager] Missing AMPLITUDE_API_KEY. Check Info.plist + xcconfig mapping.")
            return
        }

        let config = Configuration(
            apiKey: apiKey,
            logLevel: logLevel,
            autocapture: autocapture
        )

        queue.sync {
            let c = Amplitude(configuration: config)
            if let uid = userId {
                c.setUserId(userId: "USER_ID: \(uid)")
            }
            self.client = c
        }
    }

    func bindUser(id: String) {
        queue.async { [weak self] in
            guard let self, let client = self.client else { return }
            client.setUserId(userId: "USER_ID: \(id)")
        }
    }

    func track(_ event: AmplitudeEvent, _ properties: [String: Any?] = [:]) {
        track(event.rawValue, properties)
    }

    func track(_ event: String, _ properties: [String: Any?] = [:]) {
        queue.async { [weak self] in
            guard let self, let client = self.client else { return }
            let props = Self.clean(properties)
            client.track(eventType: event, eventProperties: props)
        }
    }

    func trackScreen(_ screen: ScreenName, _ properties: [String: Any?] = [:]) {
        var props = properties
        props[AmplitudePropertyKey.screenName.rawValue] = screen.rawValue
        track("screen_view", props)
    }

    func identify(
        set: [String: Any?] = [:],
        add: [String: Double] = [:],
        unset: [String] = [],
        append: [String: Any?] = [:],
        setOnce: [String: Any?] = [:]
    ) {
        queue.async { [weak self] in
            guard let self, let client = self.client else { return }
            let i = Identify()
            set.forEach { i.set(property: $0.key, value: $0.value) }
            add.forEach { i.add(property: $0.key, value: $0.value) } // 기존 코드에 add 미적용이어서 반영
            unset.forEach { i.unset(property: $0) }
            append.forEach { i.append(property: $0.key, value: $0.value) }
            setOnce.forEach { i.setOnce(property: $0.key, value: $0.value) }
            client.identify(identify: i)
        }
    }

    func setUserProperties(_ properties: [String: Any?]) {
        identify(set: properties)
    }

    func reset() {
        queue.async { [weak self] in
            guard let self, let client = self.client else { return }
            client.reset()
        }
    }

    func flush() {
        queue.async { [weak self] in
            guard let self, let client = self.client else { return }
            client.flush()
        }
    }

    var deviceId: String? {
        queue.sync { client?.getDeviceId() }
    }
}

// MARK: - Helpers
private extension AmplitudeManager {
    static func readApiKey() -> String? {
        Bundle.main.object(forInfoDictionaryKey: "AMPLITUDE_API_KEY") as? String
    }

    static func clean(_ dict: [String: Any?]) -> [String: Any] {
        var out: [String: Any] = [:]
        dict.forEach { k, v in if let v = v { out[k] = v } }
        return out
    }
}

// MARK: - UIKit convenience
extension UIViewController {
    func amp_trackScreen(_ screen: ScreenName, extra: [String: Any?] = [:]) {
        AmplitudeManager.shared.trackScreen(screen, extra)
    }
}

extension AmplitudeManager {
    /// 타이머 시작
    func timerStart(_ key: String) {
        queue.async { [weak self] in self?.timers[key] = Date() }
    }

    /// 타이머 종료(초 단위 반환). 없으면 0
    @discardableResult
    func timerEndSeconds(_ key: String) -> Int {
        var start: Date?
        queue.sync { start = timers.removeValue(forKey: key) }
        guard let s = start else { return 0 }
        return Int(Date().timeIntervalSince(s).rounded())
    }

    /// 사용자 프로퍼티 값을 누적(+)
    func incrementUserProperty(_ key: String, by value: Double = 1) {
        queue.async { [weak self] in
            guard let self, let client = self.client else { return }
            let identify = Identify()
            identify.add(property: key, value: value)
            client.identify(identify: identify)
        }
    }
}

typealias AmpProps = [String: Any?]

func props(_ items: (String, Any)... ) -> AmpProps {
    var dict: AmpProps = [:]
    items.forEach { dict[$0.0] = $0.1 }
    return dict
}
