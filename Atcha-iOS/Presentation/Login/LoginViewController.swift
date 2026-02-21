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
    private let backgroundImageView: UIImageView = UIImageView()
    private let kakaoLoginButton: UIButton = UIButton(type: .custom)
    private let appleLoginButton: UIButton = UIButton(type: .custom)
    
    private let pageControl = UIPageControl()
    private var autoScrollTimer: Timer?
    private let multiplier = 3 // 실제 아이템 수 * multiplier 만큼 셀 생성
    private var isInitialSetup = true
    
    private let gradientLayer = CAGradientLayer()
    
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = backgroundImageView.bounds
        
        // 컬렉션뷰 레이아웃이 완료된 후 중간 위치로 초기화
        if isInitialSetup {
            let itemCount = LoginIntro.allCases.count
            let middleIndex = itemCount * (multiplier / 2)
            let indexPath = IndexPath(item: middleIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            isInitialSetup = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        autoScrollTimer = Timer.scheduledTimer(timeInterval: 4.0,
                                               target: self,
                                               selector: #selector(goToNextPage),
                                               userInfo: nil,
                                               repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    private func setupUI() {
        view.addSubViews(backgroundImageView, pageControl, collectionView, loginButtonStackView)
        
        // 수직 그라데이션 배경 적용 (top: #121212, bottom: #1E1E1E)
        let topColor = UIColor(red: 0x12/255.0, green: 0x12/255.0, blue: 0x12/255.0, alpha: 1.0)
        let bottomColor = UIColor(red: 0x2C/255.0, green: 0x2C/255.0, blue: 0x2E/255.0, alpha: 1.0)
        
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        backgroundImageView.layer.insertSublayer(gradientLayer, at: 0)
        
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
            make.bottom.equalToSuperview().inset(40)
        }
    }
    
    @objc private func goToNextPage() {
        let itemsPerPage = LoginIntro.allCases.count
        let currentOffset = collectionView.contentOffset.x
        let pageWidth = collectionView.bounds.width
        let currentPage = Int(currentOffset / pageWidth)
        let nextPage = currentPage + 1
        
        let indexPath = IndexPath(item: nextPage, section: 0)
        collectionView.scrollToItem(at: indexPath,
                                    at: .centeredHorizontally,
                                    animated: true)
        
        // 실제 페이지 번호 업데이트 (0-5 범위 내에서)
        let actualPage = nextPage % itemsPerPage
        pageControl.currentPage = actualPage
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

extension LoginViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 무한 스크롤을 위해 실제 아이템 수의 배수만큼 생성
        return LoginIntro.allCases.count * multiplier
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoginIntroCell.id, for: indexPath) as? LoginIntroCell else {
            
            return UICollectionViewCell()
        }
        
        // 실제 인덱스로 변환 (0-5 범위로 순환)
        let actualIndex = indexPath.item % LoginIntro.allCases.count
        cell.configure(info: LoginIntro.allCases[actualIndex])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width,
                      height: collectionView.bounds.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let itemsPerPage = LoginIntro.allCases.count
        let pageWidth = scrollView.frame.width
        let currentPage = Int(scrollView.contentOffset.x / pageWidth + 0.5)
        
        // 실제 페이지 번호 업데이트 (0-5 범위 내에서)
        let actualPage = currentPage % itemsPerPage
        pageControl.currentPage = actualPage
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        resetScrollPositionIfNeeded()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        resetScrollPositionIfNeeded()
    }
    
    // 스크롤 위치가 끝에 가까워지면 중간으로 재배치
    private func resetScrollPositionIfNeeded() {
        let itemsPerPage = LoginIntro.allCases.count
        let pageWidth = collectionView.bounds.width
        let currentPage = Int(collectionView.contentOffset.x / pageWidth + 0.5)
        let totalPages = itemsPerPage * multiplier
        
        // 끝 부분에 가까워지면 중간으로 이동
        if currentPage <= itemsPerPage / 2 {
            let newPage = currentPage + itemsPerPage
            let newOffset = CGPoint(x: CGFloat(newPage) * pageWidth, y: 0)
            collectionView.setContentOffset(newOffset, animated: false)
        } else if currentPage >= totalPages - itemsPerPage / 2 {
            let newPage = currentPage - itemsPerPage
            let newOffset = CGPoint(x: CGFloat(newPage) * pageWidth, y: 0)
            collectionView.setContentOffset(newOffset, animated: false)
        }
    }
}

