//
//  AmplitudeEvent.swift
//  Atcha-iOS
//
//  Created by wodnd on 10/16/25.
//

import Foundation

enum AmplitudeEvent: String {
    case permission_setting = "permission_setting"
    case search_location_click = "search_location_click"
    case current_location_click = "current_location_click"
    case home_register = "home_register"
    case alarm_alert_type_setting = "alarm_alert_type_setting"
    case signup = "signup"
    case course_search_click = "course_search_click"
    case origin_search_click = "origin_search_click"
    case origin_setting = "origin_setting"
    case course_change_click = "course_change_click"
    case course_detail_toggle_click = "course_detail_toggle_click"
    case course_detail_click = "course_detail_click"
    case bus_detail_click = "bus_detail_click"
    case bus_info_click = "bus_info_click"
    case long_interval_alarm_register = "long_interval_alarm_register"
    case alarm_register = "alarm_register"
    case character_click = "character_click"
    case origin_time_click = "origin_time_click"
    case course_click = "course_click"
    case course_refresh_click = "course_refresh_click"
    case start_click = "start_click"
    case later_course_click = "later_course_click"
    case another_alarm_register = "another_alarm_register"
    case logout = "logout"
    case withdraw = "withdraw"
    case alarm_cancel = "alarm_cancel"
    case screen_view = "screen_view"
}

enum ScreenName: String {
    case splash = "스플래쉬"
    case home_register = "우리집 등록"
    case home_search = "우리집 검색"
    case home_setting = "우리집 설정"
    case alarm_setting = "알람 설정"
    case mypage = "마이페이지"
    case account = "내 계정"
    case terms = "약관"
    case main = "메인"
    case course_search = "경로 탐색"
    case course_detail = "상세 경로"
    case origin_search = "출발지 검색"
    case origin_setting = "출발지 설정"
    case alarm = "알람"
}
