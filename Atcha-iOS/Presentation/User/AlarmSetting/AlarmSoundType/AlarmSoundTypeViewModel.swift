//
//  AlarmSoundTypeViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import Foundation

final class AlarmSoundTypeViewModel: BaseViewModel {
    func saveSoundType(_ option: AlarmSoundOption) {
        print("option: \(option)")
        UserDefaultsWrapper().set(option.soundType, forKey: UserDefaultsWrapper.Key.soundType.rawValue)
    }
}
