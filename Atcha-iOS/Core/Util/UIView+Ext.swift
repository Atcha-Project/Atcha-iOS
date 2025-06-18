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

extension UIView {
    // MARK: - 사용 예시
    // view.showToast(message: "토스트 사용방법")
    func showToast(message: String, duration: TimeInterval = 2.0, topOffset: CGFloat = 10) {
        let atchaToast = AtchaToast(message: message)
        atchaToast.show(in: self, duration: duration, topOffset: topOffset)
    }
}
