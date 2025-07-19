//
//  AlarmSoundType.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import UIKit

struct AlarmSoundOption: Encodable {
    let soundType: AlarmSoundType
    var isSelected: Bool
}

enum AlarmSoundType: CaseIterable, Codable {
    case sound
    case vibration
    
    var title: String {
        switch self {
        case .sound: return "소리"
        case .vibration: return "진동"
        }
    }
    
    var icon: UIImage {
        switch self {
        case .sound: return UIImage.soundOn
        case .vibration: return UIImage.soundOff
        }
    }
}
