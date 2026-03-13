//
//  AmplitudeEvent.swift
//  Atcha-iOS
//
//  Created by wodnd on 10/16/25.
//

import Foundation

enum AmplitudeEvent: String {
    // MARK: - 온보딩
    case intro_view = "intro_view"
    case intro_start_click = "intro_start_click"
    
    // MARK: - 메인
    case main_view = "main_view" // 1. 비로그인 진입 2. 로그인 진입
    case mypage_click = "mypage_click"
    case current_location_click = "current_location_click"
    
    case departure_change_click = "departure_change_click"
    case home_change_click = "home_change_click"
    case course_search_click = "course_search_click"
    
    case login_click = "login_click"
    case home_register_view = "home_register_view" // 1.가입 2.메인 3.설정
    case home_setting_view = "home_setting_view"
    case home_setting_click = "home_search_click"
    
    case character_click = "character_click"
    case alarm_force_stop = "alarm_force_stop"
    case alarm_timeout_stop = "alarm_timeout_stop"
    case departure_time_click = "departure_time_click"
    case course_click = "course_click"
    
    
    // MARK: - 마이페이지
    case signup = "signup"
    case search_location_click = "search_location_click"
    
    case origin_search_click = "origin_search_click"
    case my_page_click = "my_page_click"
    case alarm_cancel = "alarm_cancel"

    
    // MARK: - 마이페이지
    case logout = "logout"
    case withdraw = "withdraw"
    case alarm_alert_type_setting = "alarm_alert_type_setting"
    case home_register = "home_register"
    
    // MARK: - 경로 탐색
    case course_change_click = "course_change_click"
    case course_detail_click = "course_detail_click"
    case bus_detail_click = "bus_detail_click"
    case bus_info_click = "bus_info_click"
    case long_interval_alarm_register = "long_interval_alarm_register"
    case alarm_register = "alarm_register"
    case another_alarm_register = "another_alarm_register"
    case course_refresh_click = "course_refresh_click"
    
    // MARK: - 경로 수정
    case origin_setting = "origin_setting"
    
    // MARK: - 알람화면
    case start_click = "start_click"
    case later_course_click = "later_course_click"
}

enum AmplitudePropertyKey: String {
    case alertType = "alert_type"
    case dwellTime = "dwell_time"
    case withdrawReason = "withdraw_reason"
    case social = "social"
    case userStatus = "userStatus"
    case entryPoint = "entryPoint"
}

enum AmplitudeProperty {
    static func social(_ social: SocialType) -> (String, Any) {
        (AmplitudePropertyKey.social.rawValue, social.rawValue)
    }
    
    static func alertType(_ type: AlertType) -> (String, Any) {
        (AmplitudePropertyKey.alertType.rawValue, type.rawValue)
    }
    
    static func dwellTime(seconds: Int) -> (String, Any) {
        (AmplitudePropertyKey.dwellTime.rawValue, seconds)
    }
    
    static func userStatus(_ userStatus: UserStatus) -> (String, Any) {
        (AmplitudePropertyKey.userStatus.rawValue, userStatus.rawValue)
    }
    
    static func withdrawReason(_ reason: WithdrawReason) -> (String, Any) {
        (AmplitudePropertyKey.withdrawReason.rawValue, reason.rawValue)
    }
    
    static func entryPoint(_ entryPoint: EntryPoint) -> (String, Any) {
        (AmplitudePropertyKey.entryPoint.rawValue, entryPoint.rawValue)
    }
}

enum AlertType: String {
    case soundAndVibration = "소리 및 진동"
    case onlySound = "소리"
    case onlyVibration = "진동"
}

enum WithdrawReason: String {
    case schedule_not_match = "막차 시간이 안맞아요"
    case rarely_ride = "막차를 자주 안 타요"
    case frequent_error = "잦은 에러를 겪었어요"
    case hard_to_find = "막차를 찾기가 번거로워요"
    case dont_know_how = "앱 사용법을 모르겠어요"
    case map_app_enough = "기존에 쓰던 지도 앱으로 충분해요"
}

enum SocialType: String {
    case kakao = "kakao"
    case apple = "apple"
}

enum UserStatus: String {
    case guest = "guest"
    case member = "member"
}

enum EntryPoint: String {
    case signup = "signup"
    case main = "main"
    case mypage = "mypage"
}
