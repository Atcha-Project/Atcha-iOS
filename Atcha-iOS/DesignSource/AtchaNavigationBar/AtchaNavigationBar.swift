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
    
    // 추후 확장 예시
    // static func iconTitle(...) -> UIView { ... }
    // static func search(...) -> UIView { ... }
    // static func backOnly(...) -> UIView { ... }
}
