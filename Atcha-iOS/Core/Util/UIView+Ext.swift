//
//  UIView+Ext.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/16/25.
//

import UIKit

extension UIView {
    func addSubViews(_ views: UIView...) {
        views.forEach { self.addSubview($0) }
    }
    
    func setCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        clipsToBounds = true
    }
}
