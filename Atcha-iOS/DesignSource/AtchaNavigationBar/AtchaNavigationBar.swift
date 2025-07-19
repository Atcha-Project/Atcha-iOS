//
//  AtchaNavigationBar.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/18/25.
//

import Foundation
import UIKit

enum AtchaNavigationBar {
    static func title(_ text: String? = nil,
                      shouldShowCloseButton: Bool = true,
                      onBack: (() -> Void)? = nil,
                      onClose: (() -> Void)? = nil ) -> TitleNavigationBar {
        return TitleNavigationBar(title: text,
                                  shouldShowCloseButton: shouldShowCloseButton,
                                  onTapBack: onBack,
                                  onTapClose: onClose)
    }
    
    static func iconTitle(_ text: String,
                          _ icon: UIImage,
                          onBack: (() -> Void)? = nil,
                          onClose: (() -> Void)? = nil ) -> IconTitleNavigationBar {
        return IconTitleNavigationBar(title: text, icon: icon, onTapBack: onBack, onTapClose: onClose)
    }
    
    static func search(onBack: (() -> Void)? = nil,
                       onCurrentLocation: (() -> Void)? = nil ) -> SearchNavigationBar {
        return SearchNavigationBar(onTapBack: onBack, onTapCurrentLocation: onCurrentLocation)
    }
    
    static func backOnly(onBack: (() -> Void)? = nil,
                         tintColor: UIColor = AtchaColor.white ) -> BackOnlyNavigationBar {
        return BackOnlyNavigationBar(onTapBack: onBack, tintColor: tintColor)
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
