//
//  AppConfig.swift
//  Atcha-iOS
//
//  Created by wodnd on 2/20/26.
//

import Foundation

enum AppConfig {
    private static func required(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty else {
            fatalError("Missing Info.plist key: \(key)")
        }
        return value
    }

    static var apiBaseURL: String { required("API_BASE_URL") }
    static var kakaoApiKey: String { required("KAKAO_API_KEY") }
    static var kakaoInitKey: String { required("KAKAO_INIT_KEY") }
    static var tmapApiKey: String { required("TMAP_API_KEY") }
    static var amplitudeApiKey: String { required("AMPLITUDE_API_KEY") }
    static var errorWebhookURL: String { required("ERROR_WEBHOOK_URL") }
    static var authWebhookURL: String { required("AUTH_WEBHOOK_URL") }
}
