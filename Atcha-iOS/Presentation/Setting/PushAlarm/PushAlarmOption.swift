//
//  AlarmTimeOption.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/12/25.
//

import Foundation

enum PushAlarmOption: String, CaseIterable, Codable {
    case both = "소리 및 진동"
    case onlySound = "소리"
    case onlyVibration = "진동"
}
