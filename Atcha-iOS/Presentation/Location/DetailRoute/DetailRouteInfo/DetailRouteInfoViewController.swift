//
//  DetailRouteInfoViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import UIKit
import PanModal

final class DetailRouteInfoViewController: BaseViewController<DetailRouteInfoViewModel> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .red
    }
}

extension DetailRouteInfoViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    var allowsDragToDismiss: Bool {
        return false
    }
    
    var allowsTapToDismiss: Bool {
        return false
    }
    
    var panModalBackgroundColor: UIColor {
        return .clear
    }
    
    var shortFormHeight: PanModalHeight {
        return .contentHeight(308)
    }
    
    var longFormHeight: PanModalHeight {
        return .contentHeight(580)
    }
}
