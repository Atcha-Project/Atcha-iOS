//
//  LoginViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/21/25.
//

import UIKit
import SnapKit

class LoginViewController: BaseViewController<LoginViewModel> {
    private let backgroundImageView: UIImageView = UIImageView()
    
    private let kakaoLoginButton: UIButton = UIButton(type: .custom)
    private let appleLoginButton: UIButton = UIButton(type: .custom)
    
    private let loginIntroPageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private var loginIntroPages: [UIViewController] = []
    
    private let pageControl = UIPageControl()
    private var autoScrollTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLoginIntroPages()
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
    private func setupLoginIntroPages() {
        loginIntroPages = [
            LoginIntroViewController(
                titleText: "오후 10시에 미리\n막차 알림 등록하세요",
                subtitleText: "막차를 미리 찾고 알림 설정 할 수 있도록 알림드려요.",
                image: UIImage.imgStep1),
            
            LoginIntroViewController(
                titleText: "자리에서 떠나기 전에\n여러번 막차 알림 드려요",
                subtitleText: "막차 까먹지 않게 푸시알림과 타이머를 제공해요.",
                image: UIImage.imgStep2),
            
            LoginIntroViewController(
                titleText: "탑승하는 곳까지\n시간 확인하며 걸어가요",
                subtitleText: "탑승하는 곳까지 타이머 보면서 대중교통 시간 맞춰가요",
                image: UIImage.imgStep3)
        ]
        
        loginIntroPageVC.dataSource = self
        loginIntroPageVC.delegate = self
        loginIntroPageVC.setViewControllers([loginIntroPages[0]], direction: .forward, animated: true)
        
        addChild(loginIntroPageVC)
        view.addSubview(loginIntroPageVC.view)
        loginIntroPageVC.didMove(toParent: self)
        
        loginIntroPageVC.view.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
    }
    
    // MARK: - Page Control UI
    private func setupPageControl() {
        pageControl.numberOfPages = loginIntroPages.count
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
        guard let currentVC = loginIntroPageVC.viewControllers?.first,
              let currentIndex = loginIntroPages.firstIndex(of: currentVC) else { return }
        
        let nextIndex = (currentIndex + 1) % loginIntroPages.count
        let nextVC = loginIntroPages[nextIndex]
        
        loginIntroPageVC.setViewControllers([nextVC], direction: .forward, animated: true, completion: nil)
        pageControl.currentPage = nextIndex
    }
    
    
    // MARK: - Button UI
    private func setupButtonUI() {
        let buttonStack = UIStackView(arrangedSubviews: [kakaoLoginButton, appleLoginButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        
        view.addSubview(buttonStack)
        
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

extension LoginViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let index = loginIntroPages.firstIndex(of: viewController) else { return nil }
        let previousIndex = (index - 1 + loginIntroPages.count) % loginIntroPages.count
        return loginIntroPages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let index = loginIntroPages.firstIndex(of: viewController) else { return nil }
        let nextIndex = (index + 1) % loginIntroPages.count
        return loginIntroPages[nextIndex]
    }
}

extension LoginViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        guard completed,
              let visibleVC = pageViewController.viewControllers?.first,
              let index = loginIntroPages.firstIndex(of: visibleVC) else { return }
        
        pageControl.currentPage = index
    }
}
