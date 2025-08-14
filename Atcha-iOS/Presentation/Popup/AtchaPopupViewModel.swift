//
//  AtchaPopupViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/23/25.
//

import Foundation

final class AtchaPopupViewModel: BaseViewModel {
    @Published private(set) var info: AtcahPopuInfo
    
    init(info: AtcahPopuInfo) {
        self.info = info
    }
}
