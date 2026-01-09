//
//  RefreshObserver.swift
//  Atcha-iOS
//
//  Created by wodnd on 1/8/26.
//

import Foundation
final class RefreshObserver {
    static let shared = RefreshObserver()
    private var token: NSObjectProtocol?

    private init() {
        token = NotificationCenter.default.addObserver(
            forName: .fcmDidReceiveRefresh,
            object: nil,
            queue: .main
        ) { noti in
            guard let userInfo = noti.userInfo,
                  let body = userInfo["body"] as? String else { return }

            UserDefaultsWrapper.shared.set(
                body,
                forKey: UserDefaultsWrapper.Key.departureTime.rawValue
            )

            NotificationCenter.default.post(
                name: .refreshDidUpdate,
                object: nil,
                userInfo: userInfo
            )
        }
    }
}
