//
//  LoginIntroCell.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/22/25.
//

import UIKit
import SnapKit

final class LoginIntroCell: UICollectionViewCell {
    static let id = "LoginIntroCell"
    
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    
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
    
    func configure(info: LoginIntro) {
        titleLabel.attributedText = AtchaFont.H1_B_26(info.title, color: AtchaColor.white)
        imageView.image = info.image
    }
    
    private func setupUI() {
        contentView.addSubViews(titleLabel, imageView)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
    }
    
    private func setupAutoLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.centerX.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(60)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(imageView.snp.width).multipliedBy(320.0 / 350.0)
//            make.bottom.lessThanOrEqualToSuperview().inset(40)
        }
    }
}
