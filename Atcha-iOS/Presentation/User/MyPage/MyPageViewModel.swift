//
//  MyPageViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/21/25.
//

import UIKit
import Foundation
import Combine

final class MyPageViewModel: BaseViewModel {
    let navigationTarget = PassthroughSubject<MyPageNavigationTarget, Never>()

    func didSelectItem(_ item: MyPageItem) {
        switch item {
        case .account:
            navigationTarget.send(.account)
        case .home:
            navigationTarget.send(.home)
        case .notification:
            navigationTarget.send(.notification)
        case .term:
            navigationTarget.send(.term)
        case .version(let version):
            navigationTarget.send(.versionUpdate)
        }
    }
}
