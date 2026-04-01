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
        collectionView.register(IntroCell.self,
                                forCellWithReuseIdentifier: IntroCell.id)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupButtons()
        setupAutoLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = backgroundImageView.bounds
        
        // 컬렉션뷰 레이아웃이 완료된 후 중간 위치로 초기화
        if isInitialSetup {
            let itemCount = Intro.allCases.count
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        amp_track(.intro_view)
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
        
        pageControl.numberOfPages = Intro.allCases.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = AtchaColor.white
        pageControl.pageIndicatorTintColor = AtchaColor.gray300
        pageControl.isUserInteractionEnabled = false
    }
    
    private func setupAutoLayout() {
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(pageControl.snp.top).offset(-32) // 페이지 컨트롤과의 간격
        }
        
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(guestLoginButton.snp.top).offset(-81.34)
            make.height.equalTo(6)
        }
        
        guestLoginButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(40)
            make.height.equalTo(56)
        }
    }
    
    @objc private func goToNextPage() {
        let itemsPerPage = Intro.allCases.count
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
        label.attributedText = AtchaFont.B1_R_17(lineHeight: 0, labelText, color: textColor, alignment: .center)
        label.textAlignment = .center
        
        button.layer.cornerRadius = 8
        button.layer.backgroundColor = bgColor.cgColor
        
        label.isUserInteractionEnabled = false
        
        // 스택 뷰 없이 버튼에 직접 추가
        button.addSubViews(label)
        
        
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

extension IntroViewController {
    // MARK: - Actions
    @objc private func didTapGuestLogin() {
        viewModel.guestLoginTapped()
        
        amp_track(.intro_start_click)
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
        return Intro.allCases.count * multiplier
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IntroCell.id, for: indexPath) as? IntroCell else {
            
            return UICollectionViewCell()
        }
        
        // 실제 인덱스로 변환 (0-5 범위로 순환)
        let actualIndex = indexPath.item % Intro.allCases.count
        cell.configure(info: Intro.allCases[actualIndex])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width,
                      height: collectionView.bounds.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let itemsPerPage = Intro.allCases.count
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
        let itemsPerPage = Intro.allCases.count
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

