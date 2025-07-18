//
//  MyAccountItem.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/18/25.
//

import Foundation

enum MyAccountItem: CaseIterable, MyPageProtocol {
    case logout
    case withdraw
    
    var title: String {
        switch self {
        case .logout: return "로그아웃"
        case .withdraw: return "계정 탈퇴"
        }
    }
    
    var type: AtchaListType {
        return .none
    }
}
