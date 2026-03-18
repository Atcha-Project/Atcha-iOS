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

    private let webhookURLString = "https://discord.com/api/webhooks/1483605689031983336/gqPjN3OU9ciMCF5qgPodT_KV3fE1giuuD6M4ODCJdenNru8UHezuYZfWBfc4Vnj4GWIZ"

    func sendErrorLog(
        statusCode: Int,
        method: String,
        path: String,
        responseCode: String,
        message: String,
        requestHeaders: [String: String],
        requestBody: [String: Any]? = nil,
        requestParameters: [String: Any]? = nil
    ) {
        guard let url = URL(string: webhookURLString) else { return }

        // Authorization 토큰 앞 30자만 노출
        let headersText = requestHeaders.map { key, value in
            let safeValue = key == "Authorization" ? String(value.prefix(30)) + "..." : value
            return "\(key): \(safeValue)"
        }.joined(separator: "\n")

        // body JSON 변환
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
                "color": 16711680,
                "fields": [
                    ["name": "Method & Path",     "value": "`\(method) \(path)`",          "inline": false],
                    ["name": "HTTP Status",        "value": "\(statusCode)",                 "inline": true],
                    ["name": "responseCode",       "value": responseCode,                    "inline": true],
                    ["name": "App Version",        "value": AppInfoProvider.currentVersion,  "inline": true],
                    ["name": "Error Message",      "value": message,                         "inline": false],
                    ["name": "Request Headers",    "value": "```\n\(headersText)\n```",      "inline": false],
                    ["name": "Request Parameters", "value": paramsText,                      "inline": false],  
                    ["name": "Request Body",       "value": bodyText,                        "inline": false]
                ],
                "footer": ["text": "발생 시각: \(Date().kstString)"]
            ]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request).resume()
    }
}

private extension Date {
    var kstString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self) + " KST"
    }
}
