//
//  PermissionType.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/16/25.
//

import Foundation

enum PermissionType {
    case loaction
    case push
    
    var alertTitle: String {
        switch self {
        case .loaction:
            return "위치 권한을 허용하지 않으면\n현위치의 막차를 확인할 수 없어요."
        case .push:
            return "알람을 허용하지 않으면\n막차 알람이 울리지 못해요."
        }
    }
    
    var alertCancelTitle: String {
        return "닫기"
    }
    
    var alertConfirmTitle: String {
        return "설정 하기"
    }
}
