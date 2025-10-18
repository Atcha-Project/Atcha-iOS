//
//  AmplitudeEvent.swift
//  Atcha-iOS
//
//  Created by wodnd on 10/16/25.
//

import Foundation

enum AmplitudeEvent: String {
    // MARK: - 온보딩 관련
    case onboarding_complete = "onboarding_complete" /// 온보딩 완료 수
    case onboarding_notification_permission_settings_clicked = "onboarding_notification_permission_settings_clicked" /// 알람 권한 설정하기 클릭 순
    case onboarding_notification_permission_clicked = "onboarding_notification_permission_clicked" /// 알람 권한 허용 여부 클릭 수
    case onboarding_location_permission_settings_clicked = "onboarding_location_permission_settings_clicked" /// 위치 권한 설정하기 클릭 수
    case onboarding_location_permission_clicked = "onboarding_location_permission_clicked" /// 위치 권한 허용 여부 클릭 수
    
    case home_register_permission_clicked = "homeregister_permission_clicked" /// 집등록 > 위치 접근 모달 > 허용하기 버튼 클릭 수
    case home_register_complete_clicked = "homeregister_complete_clicked" /// 알람 설정 > 알람 권한 모달 허용하기 버튼 클릭 수
    
    case alarmsetting_alarm_permission_clicked = "alarmsetting_alarm_permission_clicked" /// 알람 설정 > 알람 허용 모달 > 허용하기 버튼 클릭 수
    case user_alarm_frequencies = "user_alarm_frequencies" /// 사용자가 등록한 알람 빈도
    
    // MARK: - 경로 탐색 관련
    case alert_button = "alert_button" /// 막차 알람 받기 버튼 클릭 위치
    case alert_end_popup_2 = "alert_end_popup_2" /// 막차 종료 버튼 클릭 수
    
    case coursesearch_view_duration = "coursesearch_view_duration" /// 경로 탐색 화면 체류 시간
    case coursesearch_toggle = "coursesearch_toggle" /// 토글 disable 클릭 수
    case coursesearch_card = "coursesearch_card" /// 카드 클릭 or 상세 보기 > 클릭 수 비교
    
    // MARK: - 홈 관련
    case alert_end_popup_1 = "alert_end_popup_1" /// 막차 종료 버튼 클릭 수
    case coursesearch_entered = "coursesearch_entered" /// 홈 -> 경로 검색 진입 방식 비교
    
    case home_itinerary_clicked = "home_itinerary_clicked" /// 홈 -> 상세 경로 클릭 수
    case home_transit_icon_clicked = "home_transit_icon_clicked" /// 지도 위 대중교통 아이콘 클릭 수
    case home_destination_clicked = "home_destination_clicked" /// 도착지 영역 클릭 수
    case home_departure_time_clicked = "home_departure_time_clicked" /// 출발시간 영역 클릭 수
    case home_route_clicked = "home_route_clicked" /// 출발지 -> 도착지 영역 클릭 수
    case home_coursesearch_entered = "home_coursesearch_entered" ///홈 → 경로검색 진입 방식 비교
    
    case character_clicked_before_alarm = "character_clicked_before_alarm" /// 알람 등록 전, 캐릭터 클릭 수
    case character_clicked_after_alarm = "character_clicked_after_alarm" /// 알람 등록 후, 캐릭터 클릭 수

    
    
    // MARK: - 알람 관련
    case alarm_registered = "alarm_registered" /// 알람 등록한 경로의 특성
    case notification_registration_duration = "notification_registration_duration" /// 알람 등록 완료 소요 시간
    

    // MARK: - 잠금화면 관련
    case lock_button = "lock_button" /// 출발하기, 더 늦은 경로 확인 하기 버튼 클릭 수
    case lock_action_taken = "lock_action_taken" /// 잠금화면 알람 시간 내 사용자 액션 여부
    

    // MARK: - 마이페이지 관련
    case mypage_banner_clicked = "mypage_banner_clicked" /// 배너 클릭 수
}
