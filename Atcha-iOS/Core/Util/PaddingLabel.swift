//
//  PaddingLabel.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/1/25.
//

import Foundation
import UIKit

class PaddingLabel: UILabel {
    private var padding = UIEdgeInsets.zero

    init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        super.init(frame: .zero)
        self.padding = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + padding.left + padding.right,
                      height: size.height + padding.top + padding.bottom)
    }
}
