//
//  AlarmSoundTypeViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import UIKit

final class AlarmSoundTypeViewController: BaseViewController<AlarmSoundTypeViewModel> {
    private lazy var options: [AlarmSoundOption] = []
    private lazy var navigationBar: TitleNavigationBar = AtchaNavigationBar.title("진동/벨소리 설정", shouldShowCloseButton: false, onBack:  { [weak self] in
        guard let self else { return }
        navigationController?.popViewController(animated: true)
    })
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 20,
                                           left: 16,
                                           bottom: 0,
                                           right: 16)
        
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(AlarmSoundTypeCollectionViewCell.self,
                                forCellWithReuseIdentifier: AlarmSoundTypeCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        options = makeAlarmSoundOptions()
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
    
    private func makeAlarmSoundOptions() -> [AlarmSoundOption] {
        let savedType = UserDefaultsWrapper().object(
            forKey: UserDefaultsWrapper.Key.soundType.rawValue,
            of: AlarmSoundType.self
        )
        
        let selectedType = savedType ?? .sound

        return AlarmSoundType.allCases.map {
            AlarmSoundOption(soundType: $0, isSelected: $0 == selectedType)
        }
    }
}

extension AlarmSoundTypeViewController: UICollectionViewDelegate,
                                   UICollectionViewDataSource,
                                   UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlarmSoundTypeCollectionViewCell.identifier,
                                                            for: indexPath) as? AlarmSoundTypeCollectionViewCell else {
            return .init()
        }
        let item = options[indexPath.item]
        cell.configure(item)
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16
        let spacing: CGFloat = 12
        let width: CGFloat = collectionView.bounds.width - (2 * padding) - (spacing)
        
        return CGSize(width: width / 2.0, height: width / 2.0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        for i in 0..<options.count {
            options[i].isSelected = (i == indexPath.item)
        }
        viewModel.saveSoundType(options[indexPath.row])
        collectionView.reloadData()
    }
}

