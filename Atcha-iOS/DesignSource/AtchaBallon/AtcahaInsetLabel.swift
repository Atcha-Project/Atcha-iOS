//
//  AtcahaInsetLabel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/26/25.
//

import Foundation
import UIKit

class AtcahaInsetLabel: UILabel {
    let topInset = CGFloat(10)
    let bottomInset = CGFloat(10)
    let leftInset = CGFloat(12)
    let rightInset = CGFloat(12)
    
    override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override public var intrinsicContentSize: CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize
        intrinsicSuperViewContentSize.height += topInset + bottomInset
        intrinsicSuperViewContentSize.width += leftInset + rightInset
        return intrinsicSuperViewContentSize
    }
}
