//
//  IntroViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 3/3/26.
//

import UIKit
import SnapKit
import AuthenticationServices
import QuartzCore

final class IntroViewController: BaseViewController<IntroViewModel> {
    private var appleLoginDelegateWrapper: AppleLoginDelegateWrapper?
    private let backgroundImageView: UIImageView = UIImageView()
    private let guestLoginButton: UIButton = UIButton(type: .custom)
    
    private let pageControl = UIPageControl()
    private var autoScrollTimer: Timer?
    private let multiplier = 3
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupButtons()
        setupAutoLayout()
        
        UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.isGuest.rawValue)
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
        view.addSubViews(backgroundImageView, pageControl, collectionView, guestLoginButton)
        
        let topColor = UIColor(red: 0x0A/255.0, green: 0x0A/255.0, blue: 0x0A/255.0, alpha: 1.0)
        let bottomColor = UIColor(red: 0x18/255.0, green: 0x18/255.0, blue: 0x1A/255.0, alpha: 1.0)
        
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
            make.bottom.equalTo(guestLoginButton.snp.top)
        }
        
        guestLoginButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(40)
            make.height.equalTo(56)
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
    
    private func setupButtons() {
        configureLoginButton(
            button: guestLoginButton,
            labelText: "앗차 시작하기",
            textColor: AtchaColor.white,
            bgColor: AtchaColor.gray910
        )
        
        guestLoginButton.addTarget(self, action: #selector(didTapGuestLogin), for: .touchUpInside)
    }
    
    private func configureLoginButton(button: UIButton,
                                      labelText: String,
                                      textColor: UIColor,
                                      bgColor: UIColor) {
        
        
        let label = UILabel()
        label.attributedText = AtchaFont.B1_R_17(labelText, color: textColor)
        label.textAlignment = .center
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        
        stackView.addArrangedSubview(label)
        
        button.layer.cornerRadius = 8
        button.layer.backgroundColor = bgColor.cgColor
        
        
        stackView.isUserInteractionEnabled = false
        label.isUserInteractionEnabled = false
        
        button.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}

extension IntroViewController {
    // MARK: - Actions
    @objc private func didTapGuestLogin() {
        viewModel.guestLoginTapped()
    }
}

extension IntroViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

extension IntroViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
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

