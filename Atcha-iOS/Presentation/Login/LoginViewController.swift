//
//  LoginViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/21/25.
//

import UIKit
import SnapKit
import AuthenticationServices

final class LoginViewController: BaseViewController<LoginViewModel> {
    private var appleLoginDelegateWrapper: AppleLoginDelegateWrapper?
    private let backgroundImageView: UIImageView = UIImageView()
    private let kakaoLoginButton: UIButton = UIButton(type: .custom)
    private let appleLoginButton: UIButton = UIButton(type: .custom)
    
    private let pageControl = UIPageControl()
    private var autoScrollTimer: Timer?
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(LoginIntroCell.self,
                                forCellWithReuseIdentifier: LoginIntroCell.id)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLoginButtons()
        setupAutoLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        autoScrollTimer = Timer.scheduledTimer(timeInterval: 4.0,
//                                               target: self,
//                                               selector: #selector(goToNextPage),
//                                               userInfo: nil,
//                                               repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        autoScrollTimer?.invalidate()
//        autoScrollTimer = nil
    }
    
    private func setupUI() {
        view.addSubViews(backgroundImageView, pageControl, collectionView, loginButtonStackView)
        
        backgroundImageView.image = UIImage.splashBG
        
        pageControl.numberOfPages = LoginIntro.allCases.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = AtchaColor.main
        pageControl.pageIndicatorTintColor = AtchaColor.gray300
        pageControl.isUserInteractionEnabled = false
    }
    
    private func setupAutoLayout() {
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(56)
        }
        
        collectionView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(pageControl.snp.bottom)
            make.bottom.equalTo(loginButtonStackView.snp.top)
        }
        
        loginButtonStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    @objc private func goToNextPage() {
        let currentPage = pageControl.currentPage
        let nextPage = (currentPage + 1) % LoginIntro.allCases.count
        let indexPath = IndexPath(item: nextPage, section: 0)
        
        collectionView.scrollToItem(at: indexPath,
                                    at: .centeredHorizontally,
                                    animated: true)
        pageControl.currentPage = nextPage
    }
    
    private func setupLoginButtons() {
        configureLoginButton(
            button: kakaoLoginButton,
            icon: UIImage.kakao,
            labelText: "카카오 계정으로 계속하기",
            textColor: AtchaColor.black,
            bgColor: AtchaColor.Etc.kakao,
            iconTint: AtchaColor.Etc.kakaoLogo
        )
        
        configureLoginButton(
            button: appleLoginButton,
            icon: UIImage.apple,
            labelText: "Apple 계정으로 계속하기",
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
        label.attributedText = AtchaFont.B2_SB_15(labelText, color: textColor)
        label.textAlignment = .center
        
        button.layer.cornerRadius = 8
        button.layer.backgroundColor = bgColor.cgColor
        
        button.addSubview(iconView)
        button.addSubview(label)
        
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.leading.equalToSuperview().inset(22)
            make.centerY.equalToSuperview()
        }
        
        label.snp.makeConstraints { make in
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

extension LoginViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return LoginIntro.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoginIntroCell.id, for: indexPath) as? LoginIntroCell else {
            
            return UICollectionViewCell()
        }
        
        cell.configure(info: LoginIntro.allCases[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width,
                      height: collectionView.bounds.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width + 0.5)
        pageControl.currentPage = page
    }
}
