//
//  AlarmSoundTypeCollectionViewCell.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import Foundation
import UIKit

final class AlarmSoundTypeCollectionViewCell: UICollectionViewCell {
    static let identifier: String = "AlarmSoundTypeCollectionViewCell"
    
    private let iconImageView: UIImageView = UIImageView()
    private let titleLabel: UILabel = UILabel()
    private let selectImageView: UIImageView = UIImageView()
    private let topStack = UIStackView()
    private let middleStack = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = UIColor.gray940
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        selectImageView.contentMode = .scaleAspectFit
        selectImageView.tintColor = .white
        titleLabel.textAlignment = .center
        
        middleStack.axis = .vertical
        middleStack.alignment = .center
        middleStack.spacing = 18
        middleStack.addArrangedSubview(titleLabel)
        middleStack.addArrangedSubview(selectImageView)
        
        topStack.axis = .vertical
        topStack.alignment = .center
        topStack.spacing = 12
        topStack.addArrangedSubview(iconImageView)
        topStack.addArrangedSubview(middleStack)
        
        contentView.addSubview(topStack)
    }
    
    private func setupAutoLayout() {
        topStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        
        selectImageView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }
    }
    
    func configure(_ option: AlarmSoundOption) {
        iconImageView.image = option.soundType.icon
        titleLabel.attributedText = AtchaFont.B4_R_15(option.soundType.title)
        
        iconImageView.tintColor = option.isSelected ? .main : .white
        titleLabel.textColor = option.isSelected ? .main : .white
        selectImageView.tintColor = option.isSelected ? .main : .white
        selectImageView.image = option.isSelected ? UIImage.radioOn : UIImage.radioOff
    }
}
