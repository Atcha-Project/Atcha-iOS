//
//  BusIcon.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/3/25.
//

import Foundation
import UIKit

enum BusType: Int {
    case regular = 1
    case town = 3
    case mainline = 11
    case widearea = 14
    
    var backgroundColor: UIColor {
        switch self {
        case .regular: return AtchaColor.Bus.regular
        case .town: return AtchaColor.Bus.town
        case .mainline: return AtchaColor.Bus.mainline
        case .widearea: return AtchaColor.Bus.widearea
        }
    }
}

final class BusIconView: UIView {
    
    private let circleView = UIView()
    private let iconImageView = UIImageView()
    
    init(type: BusType, icon: UIImage, iconSize: CGFloat = 11.56, diameter: CGFloat = 20.22) {
        super.init(frame: .zero)
        
        backgroundColor = .clear
        
        circleView.backgroundColor = type.backgroundColor
        circleView.layer.cornerRadius = diameter / 2
        circleView.clipsToBounds = true
        addSubview(circleView)
        
        circleView.snp.makeConstraints { make in
            make.width.height.equalTo(diameter)
            make.center.equalToSuperview()
        }
        
        iconImageView.image = icon
        iconImageView.contentMode = .scaleAspectFit
        circleView.addSubview(iconImageView)
        
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(iconSize)
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
