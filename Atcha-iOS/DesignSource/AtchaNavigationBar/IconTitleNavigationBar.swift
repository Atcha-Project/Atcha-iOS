//
//  IconTitleNavigationBar.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/18/25.
//

import Foundation
import UIKit
import SnapKit

//MARK: - Icon, Title NavigationBar
final class IconTitleNavigationBar: UIView{
    
    var onTapBack: (() -> Void)?
    var onTapClose: (() -> Void)?
    
    private let backButton = UIButton()
    private let titleLabel = UILabel()
    private let iconImage = UIImageView()
    private let closeButton = UIButton()
    
    init(title: String,
         icon: UIImage,
         onTapBack: (() -> Void)? = nil,
         onTapClose: (() -> Void)? = nil) {
        self.onTapBack = onTapBack
        self.onTapClose = onTapClose
        super.init(frame: .zero)
        
        setupUI(title: title, icon: icon)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - IconTitle NavigationBar UI
    private func setupUI(title: String, icon: UIImage){
        backgroundColor = AtchaColor.gray950
        
        backButton.setImage(UIImage.chevronLeft, for: .normal)
        backButton.tintColor = AtchaColor.gray300
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        closeButton.setImage(UIImage.x, for: .normal)
        closeButton.tintColor = AtchaColor.gray300
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        
        iconImage.image = icon
        iconImage.tintColor = AtchaColor.white
        iconImage.contentMode = .scaleAspectFit
        
        titleLabel.attributedText = AtchaFont.H5_SB_17(title)
        titleLabel.text = title
        titleLabel.textColor = AtchaColor.white
        
        // 폰트의 lineHeight가 글자 크기보다 커서 시각적으로 아래로 눌려 보이는 현상 보정용
        // → UIView로 감싸고 centerY에 offset을 줘서 수직 정렬 맞춤
        let titleLabelWrapper = UIView()
        titleLabelWrapper.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-2)
        }
        titleLabelWrapper.snp.makeConstraints {
            $0.width.equalTo(titleLabel)
            $0.height.equalTo(titleLabel)
        }
        
        let iconTitleStack = UIStackView(arrangedSubviews: [iconImage, titleLabelWrapper])
        iconTitleStack.axis = .horizontal
        iconTitleStack.spacing = 2
        iconTitleStack.alignment = .center
        iconTitleStack.distribution = .fill
        
        addSubview(backButton)
        addSubview(iconTitleStack)
        addSubview(closeButton)
        
        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
        
        closeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
        
        iconImage.snp.makeConstraints {
            $0.size.equalTo(18)
        }
        
        iconTitleStack.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        snp.makeConstraints { $0.height.equalTo(60) }
    }
    
    //MARK: - Action Method
    @objc private func didTapBack() {
        onTapBack?()
    }
    
    @objc private func didTapClose() {
        onTapClose?()
    }
}
