//
//  AlarmSettingViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import Foundation

final class AlarmSettingViewModel: BaseViewModel {
    @Published var item: AlarmSettingItem?
    
    func listTapped(_ type: AlarmSettingItem) {
        item = type
    }
}
