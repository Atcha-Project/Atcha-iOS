//
//  AlarmSettingDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import Foundation

final class AlarmSettingDIContainer {
    func makeAlarmSettingViewModel() -> AlarmSettingViewModel {
        return AlarmSettingViewModel()
    }
    
    func makeAlarmSettingViewController(viewModel: AlarmSettingViewModel) -> AlarmSettingViewController {
        return AlarmSettingViewController(viewModel: viewModel)
    }
}
