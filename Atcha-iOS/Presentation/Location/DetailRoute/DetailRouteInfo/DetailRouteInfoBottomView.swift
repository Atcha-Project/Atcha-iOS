//
//  DetailRouteInfoBottomView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import UIKit
import PanModal

final class DetailRouteInfoBottomView: UIView {
    private let minHeightRatio: CGFloat = 0.45
    private let maxHeightRatio: CGFloat = 0.78
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var currentState: SheetState = .collapsed
    
    private let handleView: UIView = UIView()
    private let timeLabel: UILabel = UILabel()
    
    enum SheetState {
        case expanded
        case collapsed
    }
    
    private var parentViewHeight: CGFloat {
        return superview?.frame.height ?? UIScreen.main.bounds.height
    }
    
    private var collapsedHeight: CGFloat {
        return parentViewHeight * minHeightRatio
    }
    
    private var expandedHeight: CGFloat {
        return parentViewHeight * maxHeightRatio
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupPanGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupPanGesture()
    }
    
    private func setupView() {
        backgroundColor = .gray950
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    private func setupPanGesture() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        let translation = recognizer.translation(in: superview)
        
        switch recognizer.state {
        case .changed:
            let newY = max(parentViewHeight - expandedHeight,
                           min(self.frame.origin.y + translation.y, parentViewHeight - collapsedHeight))
            self.frame.origin.y = newY
            recognizer.setTranslation(.zero, in: superview)
            
        case .ended:
            let velocity = recognizer.velocity(in: superview).y
            let shouldExpand = velocity < 0
            animateTransition(shouldExpand: shouldExpand)
            
        default:
            break
        }
    }
    
    private func animateTransition(shouldExpand: Bool) {
        guard let _ = self.superview else { return }
        let targetY = shouldExpand ? (parentViewHeight - expandedHeight) : (parentViewHeight - collapsedHeight)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: [.curveEaseInOut], animations: {
            self.frame.origin.y = targetY
        }, completion: { _ in
            self.currentState = shouldExpand ? .expanded : .collapsed
        })
    }
}
