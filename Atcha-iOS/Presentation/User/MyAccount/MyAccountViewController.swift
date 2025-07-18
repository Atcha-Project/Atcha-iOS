//
//  MyAccountViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/18/25.
//

import Foundation
import UIKit

final class MyAccountViewController: BaseViewController<MyAccountViewModel> {
    private lazy var navigationBar: TitleNavigationBar = AtchaNavigationBar.title("내 계정", onClose: { [weak self] in
        guard let self else { return }
        navigationController?.popViewController(animated: true)
    })
    
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
    }
    
    private func setupUI() {
        view.addSubViews(navigationBar,
                         collectionView)
    }
    
    private func setupAutoLayout() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension MyAccountViewController: UICollectionViewDelegate,
                                   UICollectionViewDataSource,
                                   UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return MyAccountItem.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyPageCell.identifier,
                                                            for: indexPath) as? MyPageCell else {
            return .init()
        }
        let item = MyAccountItem.allCases[indexPath.item]
        cell.configure(with: item)
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 52)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let selectedItem = MyAccountItem.allCases[indexPath.row]
        switch selectedItem {
        case .logout:
            print("로그아웃")
        case .withdraw:
            viewModel.signOutTapped()
        }
    }
}

