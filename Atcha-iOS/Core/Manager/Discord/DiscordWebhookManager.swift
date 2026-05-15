//
//  DiscordWebhookManager.swift
//  Atcha-iOS
//
//  Created by wodnd on 3/18/26.
//

import Foundation

final class DiscordWebhookManager {
    static let shared = DiscordWebhookManager()
    private init() {}
    
    private let errorWebhookURLString = AppConfig.errorWebhookURL
    private let authWebhookURLString = AppConfig.authWebhookURL
    
    private var environment: String {
        let baseURL = AppConfig.apiBaseURL
        if baseURL.contains("p-e.kr") {
            return "🔧 DEV"
        } else if baseURL.contains("online") {
            return "🚀 PROD"
        }
        return "❓ UNKNOWN"
    }
    
    // MARK: - 오류 로그
    func sendErrorLog(
        baseURL: String,
        statusCode: Int,
        method: String,
        path: String,
        responseCode: String,
        message: String,
        requestHeaders: [String: String],
        requestBody: [String: Any]? = nil,
        requestParameters: [String: Any]? = nil
    ) {
        guard let url = URL(string: errorWebhookURLString) else { return }
        
        let headersText = requestHeaders.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        
        let bodyText: String
        if let body = requestBody,
           let data = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            bodyText = "```json\n\(str)\n```"
        } else {
            bodyText = "None"
        }
        
        let paramsText: String
        if let params = requestParameters,
           let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            paramsText = "```json\n\(str)\n```"
        } else {
            paramsText = "None"
        }
        
        let payload: [String: Any] = [
            "content": "🚨 [Atcha-iOS] API 에러 발생!",
            "embeds": [[
                "title": "서버 에러 상세 보고",
                "color": 16711680, // 빨강
                "fields": [
                    ["name": "Base URL",           "value": "`\(baseURL)`",                  "inline": false],
                    ["name": "Method & Path",      "value": "`\(method) \(path)`",           "inline": false],
                    ["name": "HTTP Status",        "value": "\(statusCode)",                  "inline": true],
                    ["name": "responseCode",       "value": responseCode,                     "inline": true],
                    ["name": "App Version",        "value": AppInfoProvider.currentVersion,   "inline": true],
                    ["name": "Error Message",      "value": message,                          "inline": false],
                    ["name": "Request Headers",    "value": "```\n\(headersText)\n```",       "inline": false],
                    ["name": "Request Parameters", "value": paramsText,                       "inline": false],
                    ["name": "Request Body",       "value": bodyText,                         "inline": false]
                ],
                "footer": ["text": "발생 시각: \(Date().kstString)"]
            ]]
        ]
        
        sendToWebhook(url: url, payload: payload)
    }
    
    // MARK: - 로그인/탈퇴 로그
    func sendAuthLog(event: AuthEvent, userID: String, provider: String? = nil, reason: String? = nil) {
        guard let url = URL(string: authWebhookURLString) else { return }
        
        var fields: [[String: Any]] = [
            ["name": "Environment", "value": environment,                      "inline": true],
            ["name": "이벤트",      "value": event.title,                   "inline": true],
            ["name": "유저 ID",     "value": "`\(userID)`",                 "inline": true],
            ["name": "App Version", "value": AppInfoProvider.currentVersion, "inline": true]
        ]
        
        if let provider {
            fields.append(["name": "로그인 방식", "value": provider, "inline": true])
        }
        
        if let reason {
            fields.append(["name": "탈퇴 사유", "value": reason, "inline": false])
        }
        
        let payload: [String: Any] = [
            "content": event.headerMessage,
            "embeds": [[
                "title": event.embedTitle,
                "color": event.color,
                "fields": fields,
                "footer": ["text": "발생 시각: \(Date().kstString)"]
            ]]
        ]
        
        sendToWebhook(url: url, payload: payload)
    }
    
    // MARK: - 공통 전송
    private func sendToWebhook(url: URL, payload: [String: Any]) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request).resume()
    }
}

// MARK: - Auth Event 타입
enum AuthEvent {
    case login
    case signup
    case logout
    case withdraw
    
    var title: String {
        switch self {
        case .login:    return "로그인"
        case .signup:   return "회원가입"
        case .logout:   return "로그아웃"
        case .withdraw: return "회원탈퇴"
        }
    }
    
    var embedTitle: String {
        switch self {
        case .login:    return "로그인 이벤트"
        case .signup:   return "회원가입 이벤트"
        case .logout:   return "로그아웃 이벤트"
        case .withdraw: return "회원탈퇴 이벤트"
        }
    }
    
    var headerMessage: String {
        switch self {
        case .login:    return "✅ [Atcha-iOS] 로그인"
        case .signup:   return "🎉 [Atcha-iOS] 회원가입"
        case .logout:   return "👋 [Atcha-iOS] 로그아웃"
        case .withdraw: return "❌ [Atcha-iOS] 회원탈퇴"
        }
    }
    
    var color: Int {
        switch self {
        case .login:    return 3066993   // 초록
        case .signup:   return 5814783   // 파랑  
        case .logout:   return 16776960  // 노랑
        case .withdraw: return 10038562  // 보라
        }
    }
}

// MARK: - Date Extension
private extension Date {
    var kstString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self) + " KST"
    }
}
