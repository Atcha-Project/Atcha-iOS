//
//  LoginViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/21/25.
//

import UIKit
import SnapKit
import AuthenticationServices
import QuartzCore

final class LoginViewController: BaseViewController<LoginViewModel> {
    private var appleLoginDelegateWrapper: AppleLoginDelegateWrapper?
    private let kakaoLoginButton: UIButton = UIButton(type: .custom)
    private let appleLoginButton: UIButton = UIButton(type: .custom)
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.attributedText = AtchaFont.H2_B_22("딱 3초면 돼요!")
        label.textColor = AtchaColor.white
        return label
    }()
    
    
    private lazy var loginButtonStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [kakaoLoginButton,
                                                   appleLoginButton])
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 12
        return stack
    }()
    
    private let dimView = UIView()
    private let containerView = UIView()
    private let sheetHeight: CGFloat = 244
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDim()
        setupUI()
        setupLoginButtons()
        setupAutoLayout()
        
        UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.isGuest.rawValue)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dimView.alpha = 1
    }
    
    private func setupDim() {
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        dimView.alpha = 0
        view.addSubview(dimView)
    }
    
    private func setupUI() {
        containerView.backgroundColor = .gray940
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        
        view.backgroundColor = .clear
        containerView.addSubViews(titleLabel, loginButtonStackView)

    }
    
    private func setupAutoLayout() {
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(sheetHeight)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.leading.equalToSuperview().inset(24)
        }
        
        loginButtonStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview().inset(40)
        }
    }
    
    
    private func setupLoginButtons() {
        configureLoginButton(
            button: kakaoLoginButton,
            icon: UIImage.kakao,
            labelText: "카카오로 계속하기",
            textColor: AtchaColor.black,
            bgColor: AtchaColor.Etc.kakao,
            iconTint: AtchaColor.Etc.kakaoLogo
        )
        
        configureLoginButton(
            button: appleLoginButton,
            icon: UIImage.apple,
            labelText: "Apple로 계속하기",
            textColor: AtchaColor.white,
            bgColor: AtchaColor.black,
            iconTint: AtchaColor.white
        )
        
        kakaoLoginButton.addTarget(self, action: #selector(didTapKakaoLoginButton), for: .touchUpInside)
        appleLoginButton.addTarget(self, action: #selector(didTapAppleLoginButton), for: .touchUpInside)
    }
    
    private func configureLoginButton(button: UIButton,
                                      icon: UIImage,
                                      labelText: String,
                                      textColor: UIColor,
                                      bgColor: UIColor,
                                      iconTint: UIColor) {
        
        let iconView = UIImageView(image: icon)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = iconTint
        
        let label = UILabel()
        label.attributedText = AtchaFont.B_15(labelText, color: textColor)
        label.textAlignment = .center
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(label)
        
        button.layer.cornerRadius = 8
        button.layer.backgroundColor = bgColor.cgColor
        
        
        stackView.isUserInteractionEnabled = false
        iconView.isUserInteractionEnabled = false
        label.isUserInteractionEnabled = false
        
        button.addSubview(stackView)
        
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        
        stackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        button.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(52)
        }
    }
}

extension LoginViewController {
    // MARK: - Actions
    @objc private func didTapKakaoLoginButton() {
        print("카카오 로그인 버튼 터치됨")
        viewModel.kakaoLoginTapped()
    }
    
    @objc private func didTapAppleLoginButton() {
        print("애플 로그인 버튼 터치됨")
        viewModel.appleLoginTapped(
            presentationContextProvider: self
        ) { [weak self] delegate in
            self?.appleLoginDelegateWrapper = delegate
        }
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
