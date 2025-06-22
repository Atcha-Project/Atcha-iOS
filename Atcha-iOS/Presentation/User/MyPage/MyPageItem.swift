//
//  MyPageItem.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/21/25.
//

import Foundation

enum MyPageItem: CaseIterable {
    static var allCases: [MyPageItem] = [.account, home, notification, .term, version(version: "")]
    
    case account
    case home
    case notification
    case term
    case version(version: String)
    
    var title: String {
        switch self {
        case .account: return "내 계정"
        case .home: return "우리집 변경"
        case .notification: return "알림 설정"
        case .term: return "약관"
        case .version(let version): return "현재 버전 \(version)"
        }
    }
    
    var type: AtchaListType {
        switch self {
        case .version(let version):
            return .none
        default:
            return .arrow
        }
    }
}
