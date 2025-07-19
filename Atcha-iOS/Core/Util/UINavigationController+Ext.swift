//
//  UINavigationController+Ext.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/20/25.
//

import UIKit

extension UINavigationController {
    func popToViewController<T: UIViewController>(ofType type: T.Type, animated: Bool = true) {
        if let targetVC = viewControllers.first(where: { $0 is T }) {
            popToViewController(targetVC, animated: animated)
        } else {
            popToRootViewController(animated: animated)
        }
    }
}
