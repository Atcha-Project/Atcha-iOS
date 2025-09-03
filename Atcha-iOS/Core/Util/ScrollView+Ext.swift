//
//  ScrollView+Ext.swift
//  Atcha-iOS
//
//  Created by wodnd on 9/3/25.
//

import Foundation
import UIKit

extension UIScrollView {
    func scrollUp(_ points: CGFloat = 100, animated: Bool = true) {
        let minY = -adjustedContentInset.top
        let newY = max(minY, contentOffset.y - abs(points))
        setContentOffset(CGPoint(x: contentOffset.x, y: newY), animated: animated)
    }
    
    func scrollDown(_ points: CGFloat = 100, animated: Bool = true) {
        let minY = -adjustedContentInset.top
        let maxY = max(minY, contentSize.height - bounds.height + adjustedContentInset.bottom)
        let newY = min(maxY, contentOffset.y + abs(points))
        setContentOffset(CGPoint(x: contentOffset.x, y: newY), animated: animated)
    }
}
