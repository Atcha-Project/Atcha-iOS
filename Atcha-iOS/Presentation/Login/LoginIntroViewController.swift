//
//  LoginIntroViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/21/25.
//

import UIKit
import SnapKit

class LoginIntroViewController: UIViewController {
    private let titleText: String
    private let subtitleText: String
    private let image: UIImage
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let imageView = UIImageView()
    
    init(titleText: String, subtitleText: String, image: UIImage) {
        self.titleText = titleText
        self.subtitleText = subtitleText
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        setupUI()
    }
    
    private func setupUI() {
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 12
        labelStack.alignment = .center
        
        titleLabel.attributedText = AtchaFont.H2_B_26(titleText, color: AtchaColor.white)
        titleLabel.textColor = AtchaColor.white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        
        subtitleLabel.attributedText = AtchaFont.Body_R_14(subtitleText, color: AtchaColor.gray200)
        subtitleLabel.textColor = AtchaColor.white
        subtitleLabel.textAlignment = .center
        
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        
        view.addSubViews(labelStack, imageView)
        
        labelStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(40)
            make.leading.trailing.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
    }
}
