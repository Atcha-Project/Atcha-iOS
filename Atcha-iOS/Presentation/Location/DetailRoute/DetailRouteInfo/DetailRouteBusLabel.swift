//
//  DetailRouteBusLabel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 9/14/25.
//

import UIKit
import SnapKit

final class BusBadgeView: UIView {
    private let numberLabel = UILabel()
    private let arrowImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupLayout()
    }
    
    private func setupUI() {
        isUserInteractionEnabled = true
        layer.cornerRadius = 4
        clipsToBounds = true
        
        numberLabel.font = .systemFont(ofSize: 20, weight: .bold)
        numberLabel.textColor = .white
        
        arrowImageView.image = UIImage.busChevronRight
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.tintColor = UIColor.white.withAlphaComponent(0.7)
        
        addSubview(numberLabel)
        addSubview(arrowImageView)
    }
    
    private func setupLayout() {
        numberLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.equalToSuperview().inset(8)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.leading.equalTo(numberLabel.snp.trailing).offset(2)
            make.trailing.equalToSuperview().inset(5)
            make.centerY.equalToSuperview()
            make.size.equalTo(10)
        }
    }
    
    func configure(number: String?, color: UIColor?) {
        numberLabel.attributedText = AtchaFont.B6_R_14(number ?? "", color: .white)
        backgroundColor = color
    }
}
