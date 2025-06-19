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
                      onClose: (() -> Void)? = nil ) -> TitleNavigationBar {
        return TitleNavigationBar(title: text, onTapBack: onBack, onTapClose: onClose)
    }
    
    static func iconTitle(_ text: String,
                          _ icon: UIImage,
                          onBack: (() -> Void)? = nil,
                          onClose: (() -> Void)? = nil ) -> IconTitleNavigationBar {
        return IconTitleNavigationBar(title: text, icon: icon, onTapBack: onBack, onTapClose: onClose)
    }
    
    static func search(onBack: (() -> Void)? = nil,
                       onClose: (() -> Void)? = nil ) -> SearchNavigationBar {
        return SearchNavigationBar(onTapBack: onBack, onTapClose: onClose)
    }
    
    static func backOnly(onBack: (() -> Void)? = nil ) -> BackOnlyNavigationBar {
        return BackOnlyNavigationBar(onTapBack: onBack)
    }
    
    // MARK: - 사용 예시
    //
    // let navi = AtchaNavigationBar.backOnly()
    // view.addSubview(navi)
    //
    // navi.snp.makeConstraints {
    //     $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
    //     $0.leading.trailing.equalToSuperview()
    // }
}
