//
//  LoginIntroCell.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/22/25.
//

import UIKit
import SnapKit

class LoginIntroCell: UICollectionViewCell {
    static let id: String = "LoginIntroCell"
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let imageView = UIImageView()
    
    func configure(title: String, subTitle: String, image: UIImage) {
        titleLabel.attributedText = AtchaFont.H1_B_26(title, color: AtchaColor.white)
        subtitleLabel.attributedText = AtchaFont.B6_R_14(subTitle, color: AtchaColor.gray200)
        imageView.image = image
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LoginIntro Cell UI
    private func setupUI() {
        titleLabel.numberOfLines = .zero
        titleLabel.textAlignment = .center
        
        subtitleLabel.numberOfLines = .zero
        subtitleLabel.textAlignment = .center
        
        
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 12
        labelStack.alignment = .center
        
        contentView.addSubViews(labelStack, imageView)
        
        labelStack.snp.makeConstraints { make in
            make.top.equalTo(contentView.safeAreaLayoutGuide.snp.top).offset(40)
            make.leading.trailing.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
    }
}
