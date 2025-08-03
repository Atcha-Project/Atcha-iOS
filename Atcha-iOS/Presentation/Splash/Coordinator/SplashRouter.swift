//
//  SplashRouter.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/12/25.
//

import Foundation

enum SplashRouter {
    case login // 로그인
    case onboarding // 온보딩
    case main // 메인
    case lockScreen // 잠금화면
    case alarm(info: LegInfo?, address: String?) // 알람 등록 완료 된경우
}
