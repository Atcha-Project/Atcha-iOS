//
//  AmplitudeEvent.swift
//  Atcha-iOS
//
//  Created by wodnd on 10/16/25.
//

import Foundation

enum AmplitudeEvent: String {
    // MARK: - 온보딩
    case intro_view = "인트로_진입"
    case intro_start_click = "인트로_시작_클릭"
    
    // MARK: - 메인
    case main_view = "메인_진입" // 1. 비로그인 진입 2. 로그인 진입
    case mypage_click = "마이페이지_클릭"
    case current_location_click = "현재_위치_버튼_클릭"
    
    case departure_modify_click = "출발지_수정_클릭"
    case home_modify_click = "집주소_수정_클릭"
    case course_search_click = "막차_검색하기_클릭"
    
    case login_view = "로그인_진입" // 1. 마이페이지 2.출발지 수정 3.집주소 수정 4.막차검색하기
    case login_click = "로그인_클릭"
    case home_register_view = "집주소_등록_진입" // 1.가입 2.메인 3.설정
    case home_search_view = "집주소_검색_진입"
    case home_setting_view = "집주소_설정_진입"
    case home_setting_click = "집주소_설정_클릭"
    case signup = "회원가입"
    
    case character_click = "캐릭터_클릭"
    case alarm_force_stop = "알람_강제_종료"
    case alarm_timeout_stop = "알람_타임아웃_종료"
    case alarm_arrive_stop = "알람_도착_종료"
    case departure_time_click = "출발시간_영역_클릭"
    case course_click = "경로_영역_클릭"
    
    
    // MARK: - 마이페이지
    case mypage_view = "마이페이지_진입"
    case logout = "로그아웃"
    case withdraw = "회원탈퇴"
    case alarm_alert_type_setting = "알람설정"
    case term = "약관동의_진입"
    case feedback = "피드백_진입"
    
    
    // MARK: - 알람화면
    case alarm_view = "알람_진입"
    case start_click = "출발하기_클릭"
    case later_course_click = "늦은_경로_확인하기_클릭"
    
    
    // MARK: - 경로 탐색
    case course_search_view = "경로_탐색_진입"
    case course_modify_click = "경로_수정_클릭"
    case alarm_register = "알람_등록" // 1. 경로 탐색 2.경로 상세
    case another_alarm_register = "다른_알람_등록"
    case long_interval_alarm_register = "배차_긴_알람_등록"
    case course_detail_click = "경로_상세_영역_클릭"
    
    // MARK: - 경로 상세
    case course_detail_view = "경로_상세_진입"
    case course_refresh_click = "경로_새로고침_클릭"
    case bus_detail_view = "버스_상세_진입"
    case bus_detail_click = "버스_상세_클릭"
    case bus_info_click = "버스_정보_클릭"
    case bus_info_view = "버스_정보_진입"
    case bus_refresh_click = "버스_새로고침_클릭"
    case bus_info_refresh_click = "버스_정보_새로고침_클릭"
    
    
    // MARK: - 경로 수정
    case departure_modify_view = "출발지_수정_진입"
    case departure_setting_view = "출발지_설정_진입"
    case departure_setting_click = "출발지_설정_클릭"
}

enum AmplitudePropertyKey: String {
    case alertType = "알람_방식"
    case dwellTime = "알람_등록_시간"
    case withdrawReason = "탈퇴_사유"
    case social = "로그인_방식"
    case userStatus = "로그인_상태"
    case entryPoint = "진입_경로"
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
    case kakao = "카카오"
    case apple = "애플"
}

enum UserStatus: String {
    case guest = "게스트"
    case member = "로그인"
}

enum EntryPoint: String {
    case signup = "회원가입"
    case main = "메인"
    case mypage = "마이페이지"
    case departure = "출발지_수정"
    case home_modify = "집주소_수정"
    case course_search = "막차_검색하기"
}
