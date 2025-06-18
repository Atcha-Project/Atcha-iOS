//
//  AtchaNavigationBar.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/18/25.
//

import Foundation
import UIKit

enum AtchaNavigationBar {
    static func title(_ text: String,
                      onBack: (() -> Void)? = nil,
                      onClose: (() -> Void)? = nil) -> TitleNavigationBar {
        return TitleNavigationBar(title: text, onTapBack: onBack, onTapClose: onClose)
    }
    
    static func iconTitle(_ text: String,
                          _ icon: UIImage,
                      onBack: (() -> Void)? = nil,
                      onClose: (() -> Void)? = nil) -> IconTitleNavigationBar {
        return IconTitleNavigationBar(title: text, icon: icon, onTapBack: onBack, onTapClose: onClose)
    }
    
    static func backOnly(onBack: (() -> Void)? = nil) -> BackOnlyNavigationBar {
        return BackOnlyNavigationBar(onTapBack: onBack)
    }
    
    // 추후 확장 예시
    // static func search(...) -> UIView { ... }
}
