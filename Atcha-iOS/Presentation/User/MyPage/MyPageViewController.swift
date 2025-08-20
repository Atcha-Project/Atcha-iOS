//
//  MyPageViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/21/25.
//

import UIKit

final class MyPageViewController: BaseViewController<MyPageViewModel> {
    private lazy var navigationBar: UIView = AtchaNavigationBar.title("마이페이지", shouldShowCloseButton: false, onBack:  { [weak self] in
        self?.navigationController?.popViewController(animated: true)
    })
    private let footerLabel: UILabel  = UILabel()
    private let bannerImageView: UIImageView = UIImageView()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = .zero
        
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(MyPageCell.self,
                                forCellWithReuseIdentifier: MyPageCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        addGesture()
        bindViewModel()
    }
    
    private func setupUI() {
        view.addSubViews(navigationBar,
                         bannerImageView,
                         collectionView,
                         footerLabel)
        
        bannerImageView.image = UIImage.banner
        footerLabel.attributedText = AtchaFont.R_12("티맵 API와 공공데이터로 막차 정보를 제공합니다.",
                                                    color: .gray300)
    }
    
    private func bindViewModel() {
        viewModel.$didChangeAlarmSetting
            .receive(on: RunLoop.main)
            .sink { [weak self] didChange in
                guard let self, didChange else { return }
                AtchaToast(message: "알람 설정이 변경되었어요").show(in: self.view)
                self.viewModel.didChangeAlarmSetting = false
            }
            .store(in: &cancellables)
    }
    
    private func setupAutoLayout() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
        }
        bannerImageView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(bannerImageView.snp.width).multipliedBy(88.0 / 328.0)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(bannerImageView.snp.bottom).offset(20)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        footerLabel.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
            $0.centerX.equalToSuperview()
        }
    }
    
    private func addGesture() {
        bannerImageView.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(bannerTapped))
        bannerImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc func bannerTapped() {
        viewModel.bannerTapped()
    }
}

extension MyPageViewController: UICollectionViewDelegate,
                                UICollectionViewDataSource,
                                UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return MyPageItem.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyPageCell.identifier,
                                                            for: indexPath) as? MyPageCell else {
            return .init()
        }
        let item = MyPageItem.allCases[indexPath.item]
        cell.configure(with: item)
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let selectedItem = MyPageItem.allCases[indexPath.item]
        switch selectedItem {
        case .version:
            return CGSize(width: collectionView.bounds.width, height: 54)
        default:
            return CGSize(width: collectionView.bounds.width, height: 52)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedItem = MyPageItem.allCases[indexPath.item]
        switch selectedItem {
        case .account:
            viewModel.navigationTarget.send(.account)
        case .home:
            viewModel.navigationTarget.send(.home)
        case .notification:
            viewModel.navigationTarget.send(.notification)
        case .term:
            viewModel.navigationTarget.send(.term)
        case .version:
            viewModel.navigationTarget.send(.versionUpdate)
        }
    }
}
