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
    
    private(set) var environment: Environment = .dev
    
    private var timers: [String: Date] = [:]
    
    // MARK: Public API
    
    func start(
        environment: Environment = .auto,
        userId: Int? = nil,
        autocapture: AutocaptureOptions = [.sessions, .appLifecycles],
        logLevel: LogLevelEnum = .WARN
    ) {
        let resolvedEnv = environment.resolved()
        self.environment = resolvedEnv
        
        let apiKey = Self.readApiKey(for: resolvedEnv)
        guard let apiKey else {
            assertionFailure("[AmplitudeManager] Missing API Key for \(resolvedEnv). Check Info.plist.")
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
    
    
    func track(_ event: String, _ properties: [String: Any?] = [:]) {
        queue.async { [weak self] in
            guard let self, let client = self.client else { return }
            let props = Self.clean(properties)
            client.track(eventType: event, eventProperties: props)
        }
    }
    
    func trackScreen(_ name: String, _ properties: [String: Any?] = [:]) {
        var props = properties
        props["screen_name"] = name
        track("screen_viewed", props)
    }
    
    func identify(set: [String: Any?] = [:],
                  add: [String: Double] = [:],
                  unset: [String] = [],
                  append: [String: Any?] = [:],
                  setOnce: [String: Any?] = [:]) {
        queue.async { [weak self] in
            guard let self = self, let client = self.client else { return }
            let i = Identify()
            set.forEach { i.set(property: $0.key, value: $0.value) }
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

// MARK: - Environment
extension AmplitudeManager {
    enum Environment: String {
        case dev
        case prod
        case auto
        
        func resolved() -> Environment {
            switch self {
            case .dev, .prod: return self
            case .auto:
#if DEBUG
                return .dev
#else
                return .prod
#endif
            }
        }
    }
}

// MARK: - Helpers
private extension AmplitudeManager {
    static func readApiKey(for env: Environment) -> String? {
        let keyName: String = {
            switch env {
            case .dev:  return "AMPLITUDE_API_KEY_DEV"
            case .prod: return "AMPLITUDE_API_KEY_PROD"
            case .auto: return "AMPLITUDE_API_KEY_DEV"
            }
        }()
        return Bundle.main.object(forInfoDictionaryKey: keyName) as? String
    }
    
    static func clean(_ dict: [String: Any?]) -> [String: Any] {
        var out: [String: Any] = [:]
        dict.forEach { k, v in if let v = v { out[k] = v } }
        return out
    }
}

// MARK: - UIKit convenience
extension UIViewController {
    func amp_trackScreen(_ name: String? = nil, extra: [String: Any?] = [:]) {
        let screen = name ?? String(describing: type(of: self))
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
