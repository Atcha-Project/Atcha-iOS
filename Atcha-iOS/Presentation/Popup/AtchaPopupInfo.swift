//
//  AtchaPopupInfo.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/23/25.
//

import UIKit

enum AtcahPopuInfo {
    case logout
    case withdraw
    case alarm
    case course
    
    var title: String {
        switch self {
        case .logout: return "로그아웃하시겠어요?"
        case .withdraw: return "탈퇴하시겠어요?"
        case .alarm: return "막차 알람을 종료할까요?"
        case .course : return "배차 간격이 긴 버스가 포함되어\n환승 대기 시간이 길어질 수 있어요.\n막차 알람을 등록할까요?"
        }
    }
    
    var confrimTitle: String {
        switch self {
        case .logout: return "로그아웃"
        case .withdraw: return "탈퇴하기"
        case .alarm: return "종료하기"
        case .course: return "알람 받기"
        }
    }
    
    var confrimBackgroundColor: UIColor {
        switch self {
        case .alarm, .course: return .main
        default: return .white
        }
    }
    
    var confrimForegroundColor: UIColor {
        return .black
    }
    
    var cancelTitle: String {
        switch self {
        case .alarm: return "돌아가기"
        case .course: return "돌아가기"
        default: return "취소"
        }
    }
    
    var cancelBackgroundColor: UIColor {
        return .gray910
    }
    
    var cancelForegroundColor: UIColor {
        return .white
    }
}
