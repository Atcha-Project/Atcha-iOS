//
//  LoginIntroCell.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/22/25.
//

import UIKit
import SnapKit

final class IntroCell: UICollectionViewCell {
    static let id = "IntroCell"
    
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
    
    func configure(info: Intro) {
        titleLabel.attributedText = AtchaFont.H2_B_22(info.title, color: AtchaColor.white, alignment: .center)
        imageView.image = info.image
    }
    
    private func setupUI() {
        contentView.addSubViews(titleLabel, imageView)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
    }
    
    private func setupAutoLayout() {
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(125.23)
            make.centerX.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(imageView.snp.width).multipliedBy(415.55 / 392.0)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
        }
    }
}
