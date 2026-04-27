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
    case re_register
    case course
    case announeExit
    case alarmTimeout
    case arrive
    case scheduledArrive
    case serverError
    case update_essential
    case update_recommended
    case alarm_cancel
    
    var title: String {
        switch self {
        case .logout: return "로그아웃하시겠어요?"
        case .withdraw: return "탈퇴하시겠어요?"
        case .alarm: return "막차 알람을 종료할까요?"
        case .re_register: return "기존 막차 알림을 종료하고\n선택한 알람으로 변경할까요?"
        case .course : return "배차 간격이 긴 버스가 포함되어\n환승 대기 시간이 길어질 수 있어요.\n막차 알람을 등록할까요?"
        case .announeExit: return ""
        case .alarmTimeout: return "예정된 출발 시간이 지나\n알람이 자동으로 종료됐어요"
        case .arrive: return "목적지 부근에 도착해\n안내를 종료합니다"
        case .scheduledArrive: return "예정된 도착 시간이 지나\n알람이 자동으로 종료됐어요"
        case .serverError: return "잠시 후 다시 시도해주세요\n앗차팀에서 확인 및 대응 중입니다"
        case .update_essential: return "더 좋아진 앗차를 사용하기 위해\n업데이트가 필요해요"
        case .update_recommended: return "더 좋아진 앗차를 사용하기 위해\n업데이트를 권장해요"
        case .alarm_cancel: return "알람을 종료할까요?"
        }
    }
    
    var confrimTitle: String {
        switch self {
        case .logout: return "로그아웃"
        case .withdraw: return "탈퇴하기"
        case .alarm: return "종료하기"
        case .re_register: return "변경하기"
        case .course: return "알람 받기"
        case .announeExit: return "확인"
        case .alarmTimeout: return "닫기"
        case .arrive: return "확인"
        case .scheduledArrive: return "닫기"
        case .serverError: return "확인"
        case .update_essential: return "업데이트"
        case .update_recommended: return "업데이트"
        case .alarm_cancel: return "종료하기"
        }
    }
    
    var confrimBackgroundColor: UIColor {
        switch self {
        case .alarm, .re_register, .course, .arrive, .alarm_cancel: return .main
        case .alarmTimeout, .serverError, .scheduledArrive: return .gray910
        default: return .white
        }
    }
    
    var confrimForegroundColor: UIColor {
        switch self {
        case .alarmTimeout, .serverError, .scheduledArrive: return .white
        default: return .black
        }
    }
    
    var cancelTitle: String {
        switch self {
        case .alarm, .re_register: return "돌아가기"
        case .course, .alarm_cancel: return "돌아가기"
        case .update_recommended: return "나중에"
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
