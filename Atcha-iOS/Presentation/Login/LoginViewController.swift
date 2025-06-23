//
//  LoginViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/21/25.
//

import UIKit
import SnapKit

final class LoginViewController: BaseViewController<LoginViewModel> {
    private let backgroundImageView: UIImageView = UIImageView()
    
    private let kakaoLoginButton: UIButton = UIButton(type: .custom)
    private let appleLoginButton: UIButton = UIButton(type: .custom)
    
    private let pageControl = UIPageControl()
    private var autoScrollTimer: Timer?
    
    private var loginIntroCollectionView: UICollectionView!
    private let loginIntroData: [(title: String, subtitle: String, image: UIImage)] = [
        ("오후 10시에 미리\n막차 알림 등록하세요", "막차를 미리 찾고 알림 설정 할 수 있도록 알림드려요.", UIImage.imgStep1),
        ("자리에서 떠나기 전에\n여러번 막차 알림 드려요", "막차 까먹지 않게 푸시알림과 타이머를 제공해요.", UIImage.imgStep2),
        ("탑승하는 곳까지\n시간 확인하며 걸어가요", "탑승하는 곳까지 타이머 보면서 대중교통 시간 맞춰가요", UIImage.imgStep3)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLoginIntroCell()
        setupButtonUI()
        setupPageControl()
        startAutoScroll()
    }
    
    // MARK: - Base UI
    private func setupUI() {
        view.addSubview(backgroundImageView)
        
        backgroundImageView.image = UIImage.imgSplash
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Login Intro UI
    private func setupLoginIntroCell() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.itemSize = view.bounds.size
        
        loginIntroCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        loginIntroCollectionView.backgroundColor = .clear
        loginIntroCollectionView.isPagingEnabled = true
        loginIntroCollectionView.showsHorizontalScrollIndicator = false
        loginIntroCollectionView.dataSource = self
        loginIntroCollectionView.delegate = self
        loginIntroCollectionView.register(LoginIntroCell.self, forCellWithReuseIdentifier: LoginIntroCell.id)
        
        view.addSubview(loginIntroCollectionView)
        
        loginIntroCollectionView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
    }
    
    // MARK: - Page Control UI
    private func setupPageControl() {
        pageControl.numberOfPages = loginIntroData.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = AtchaColor.main
        pageControl.pageIndicatorTintColor = AtchaColor.gray300
        pageControl.isUserInteractionEnabled = false
        
        view.addSubview(pageControl)
        
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(kakaoLoginButton.snp.top).offset(-40)
        }
    }
    
    // MARK: - Auto Scroll
    private func startAutoScroll() {
        autoScrollTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(goToNextPage), userInfo: nil, repeats: true)
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    @objc private func goToNextPage() {
        let currentPage = pageControl.currentPage
        let nextPage = (currentPage + 1) % loginIntroData.count
        let indexPath = IndexPath(item: nextPage, section: 0)
        
        loginIntroCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        pageControl.currentPage = nextPage
    }
    
    
    // MARK: - Button UI
    private func setupButtonUI() {
        let buttonStack = UIStackView(arrangedSubviews: [kakaoLoginButton, appleLoginButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        
        view.addSubview(buttonStack)
        
        kakaoLoginButton.addTarget(self,
                                   action: #selector(didTapKakaoLoginButton),
                                   for: .touchUpInside)
        appleLoginButton.addTarget(self,
                                   action: #selector(didTapAppleLoginButton),
                                   for: .touchUpInside)
        
        kakaoButtonUI()
        appleButtonUI()
        
        buttonStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(24)
            make.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
        }
    }
    
    // MARK: - Kakao Button UI
    private func kakaoButtonUI() {
        let kakaoIcon = UIImageView(image: UIImage.kakao)
        kakaoIcon.tintColor = AtchaColor.Etc.kakaoLogo
        kakaoIcon.contentMode = .scaleAspectFit
        
        let kakaoLabel = UILabel()
        kakaoLabel.attributedText = AtchaFont.H6_B_15("카카오 계정으로 계속하기", color: AtchaColor.black)
        kakaoLabel.textAlignment = .center
        
        kakaoLoginButton.layer.backgroundColor = AtchaColor.Etc.kakao.cgColor
        kakaoLoginButton.layer.cornerRadius = 8
        kakaoLoginButton.addSubview(kakaoIcon)
        kakaoLoginButton.addSubview(kakaoLabel)
        
        kakaoIcon.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.leading.equalToSuperview().inset(22)
            make.centerY.equalToSuperview()
        }
        
        kakaoLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        kakaoLoginButton.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
    }
    
    // MARK: - Apple Button UI
    private func appleButtonUI() {
        let appleIcon = UIImageView(image: UIImage.apple)
        appleIcon.tintColor = AtchaColor.white
        appleIcon.contentMode = .scaleAspectFit
        
        let appleLabel = UILabel()
        appleLabel.attributedText = AtchaFont.H6_B_15("Apple 계정으로 계속하기", color: AtchaColor.white)
        appleLabel.textAlignment = .center
        
        appleLoginButton.layer.backgroundColor = AtchaColor.black.cgColor
        appleLoginButton.layer.cornerRadius = 8
        appleLoginButton.addSubview(appleIcon)
        appleLoginButton.addSubview(appleLabel)
        
        appleIcon.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.leading.equalToSuperview().inset(22)
            make.centerY.equalToSuperview()
        }
        
        appleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        appleLoginButton.snp.makeConstraints { make in
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
        viewModel.appleLoginTapped()
    }
}

extension LoginViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loginIntroData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoginIntroCell.id, for: indexPath) as? LoginIntroCell else {
            
            return UICollectionViewCell()
        }
        
        let introData = loginIntroData[indexPath.item]
        cell.configure(title: introData.title, subTitle: introData.subtitle, image: introData.image)
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width + 0.5)
        pageControl.currentPage = page
    }
}
