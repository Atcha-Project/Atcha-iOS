//
//  AlarmSettingViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import Foundation

final class AlarmSettingViewModel: BaseViewModel {
//    @Published var item: AlarmSettingItem?
    var onItemSelected: ((AlarmSettingItem) -> Void)?
    
    func listTapped(_ type: AlarmSettingItem) {
//        item = type
        onItemSelected?(type)
    }
}
