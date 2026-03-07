//
//  SplashRouter.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/12/25.
//

import Foundation

enum SplashRouter {
    case intro // 로그인
    case main // 메인
    case lockScreen(info: LegInfo?, address: String?) // 잠금화면
    case alarm(info: LegInfo?, address: String?) // 알람 등록 완료 된경우
//    case realTime(info: LegInfo?, address: String?) // 실시간 타이머
//    case finishTime(info: LegInfo? ,address: String?)
    case detailRoute(startLat: String, startLon: String, startAddress: String)
}
