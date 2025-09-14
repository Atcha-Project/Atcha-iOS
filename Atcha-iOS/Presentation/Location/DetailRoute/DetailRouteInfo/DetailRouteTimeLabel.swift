//
//  DetailRouteTimeLabel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 9/14/25.
//

import UIKit
import SnapKit

final class TimeBadgeLabel: UIView {
    
    private let label: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupAutoLayout()
    }
    
    func setText(_ text: String?) {
        label.attributedText = AtchaFont.M_11(text ?? "", color: .gray200)
    }
    
    private func setupUI() {
        backgroundColor = .gray920
        layer.cornerRadius = 4
        clipsToBounds = true
        
        label.textColor = .gray200
        label.textAlignment = .center
        
        addSubview(label)
    }
    
    private func setupAutoLayout() {
        label.snp.makeConstraints { make in
            make.width.equalTo(38)
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2,
                                                             left: 4,
                                                             bottom: 2, right: 4))
        }
    }
}
