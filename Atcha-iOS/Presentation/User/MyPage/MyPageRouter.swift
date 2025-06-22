//
//  MyPageRouter.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/22/25.
//

import UIKit
import Foundation

protocol MyPageRouter {
    func pushAccount()
    func pushHome()
    func pushNotification()
    func pushTerm()
    func openAppStore()
}

final class DefaultMyPageRouter: MyPageRouter {
    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func pushAccount() {
        print("Account 이동")
    }

    func pushHome() {
        print("Home 이동")
    }

    func pushNotification() {
        print("Notification 이동")
    }

    func pushTerm() {
        print("Term 이동")
    }

    func openAppStore() {
        print("AppStore 이동")
    }
}
