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

    // 디스코드 채널 설정에서 만든 Webhook URL
    private let webhookURLString = "https://discord.com/api/webhooks/1483605689031983336/gqPjN3OU9ciMCF5qgPodT_KV3fE1giuuD6M4ODCJdenNru8UHezuYZfWBfc4Vnj4GWIZ"

    func sendErrorLog(statusCode: Int, message: String) {
        guard let url = URL(string: webhookURLString) else { return }

        // 디코가 좋아하는 JSON 형식 (Embed를 쓰면 더 예쁘게 나옵니다)
        let payload: [String: Any] = [
            "content": "🚨 [Atcha-iOS] API 에러 발생!",
            "embeds": [[
                "title": "서버 에러 상세 보고",
                "color": 16711680, // 빨간색
                "fields": [
                    ["name": "Status Code", "value": "\(statusCode)", "inline": true],
                    ["name": "App Version", "value": AppInfoProvider.currentVersion, "inline": true],
                    ["name": "Error Message", "value": message, "inline": false]
                ],
                "footer": ["text": "발생 시각: \(Date().description)"]
            ]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        // 백그라운드에서 조용히 전송
        URLSession.shared.dataTask(with: request).resume()
    }
}
