//
//  MyPageItem.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/21/25.
//

import Foundation

protocol MyPageProtocol {
    var title: String { get }
    var type: AtchaListType { get }
}

enum MyPageItem: CaseIterable, MyPageProtocol {
    case account
    case home
    case notification
    case term
    case version
    
    var title: String {
        switch self {
        case .account: return "내 계정"
        case .home: return "우리집 변경"
        case .notification: return "알림 설정"
        case .term: return "약관"
        case .version: return "현재 버전 \(AppInfoProvider.currentVersion)"
        }
    }
    
    var type: AtchaListType {
        switch self {
        case .version:
            if AppUpdateManager.isUpdateAvailable() {
                return .button(title: "업데이트") { AppUpdateManager.openAppStore() }
            } else {
                return .none
            }
        default:
            return .arrow
        }
    }
}
