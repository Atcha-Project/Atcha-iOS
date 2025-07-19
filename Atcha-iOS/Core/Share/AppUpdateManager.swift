//
//  AppUpdateManager.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import UIKit

enum AppUpdateManager {
    static func openAppStore() {
        // TODO: appStoreConnect등록 이후, 교체작업
        guard let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    static func isUpdateAvailable() -> Bool {
        // TODO: App 최신버전 저장하기 
        let currentVersion = AppInfoProvider.currentVersion
        let latestVersion = UserDefaults.standard.string(forKey: "latestAppVersion") ?? currentVersion
        return currentVersion.compare(latestVersion, options: .numeric) == .orderedAscending
    }
}
