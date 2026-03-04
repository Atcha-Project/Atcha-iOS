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
    
    private let sheetHandler: UIView = UIView()
    
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
    private let sheetHeight: CGFloat = 198
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDim()
        setupUI()
        setupLoginButtons()
        setupAutoLayout()
        
        containerView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        setupGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.dimView.alpha = 1
            self.containerView.transform = .identity // 원래 위치로 복귀
        })
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
        
        sheetHandler.backgroundColor = AtchaColor.gray700
        sheetHandler.layer.cornerRadius = 2
        sheetHandler.clipsToBounds = true
        
        containerView.addSubViews(sheetHandler, loginButtonStackView)
        
    }
    
    private func setupAutoLayout() {
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(sheetHeight)
        }
        
        sheetHandler.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.height.equalTo(4)
            make.width.equalTo(40)
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
            labelText: "카카오톡으로 3초만에 시작",
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
        label.attributedText = AtchaFont.B_15(lineHeight: 0, labelText, color: textColor, alignment: .center)
        label.textAlignment = .center
        
        button.layer.cornerRadius = 8
        button.layer.backgroundColor = bgColor.cgColor
        
        // 터치 이벤트를 버튼이 받도록
        iconView.isUserInteractionEnabled = false
        label.isUserInteractionEnabled = false
        
        // 스택 뷰 없이 버튼에 직접 추가
        button.addSubViews(iconView, label)
        
        // 1. 아이콘: 왼쪽에서 일정 간격 띄워서 수직 중앙 정렬
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16) // 피그마 수치에 맞게 조정 (16~24 권장)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        button.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(24)
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

// MARK: - Gestures & Animations
extension LoginViewController {
    private func setupGestures() {
        // 1. 빈 배경(Dim) 터치 시 닫기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapDimView))
        dimView.addGestureRecognizer(tapGesture)
        dimView.isUserInteractionEnabled = true
        
        // 2. 시트를 아래로 스와이프해서 닫기
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        containerView.addGestureRecognizer(panGesture)
    }
    
    @objc private func didTapDimView() {
        dismissSheet()
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            // 아래로 내릴 때만 움직이게 (위로는 안 올라가게 막음)
            if translation.y > 0 {
                containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended, .cancelled:
            // 충분히 빨리 내렸거나 절반 이상 내렸으면 닫기
            if velocity.y > 1000 || translation.y > (sheetHeight / 2) {
                dismissSheet()
            } else {
                // 아니면 다시 원래 자리로 복귀 (튕겨 올라옴)
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                    self.containerView.transform = .identity
                })
            }
        default:
            break
        }
    }
    
    // 자연스럽게 시트가 내려가고 딤이 옅어지며 닫히는 애니메이션
    private func dismissSheet() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.dimView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)
        }) { _ in
            self.dismiss(animated: false) {
                self.viewModel.loginCancelled?()
            }
        }
    }
}
