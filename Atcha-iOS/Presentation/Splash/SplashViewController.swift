//
//  SplashViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import UIKit
import SnapKit

final class SplashViewController: BaseViewController<SplashViewModel> {
    private let backgroundImageView: UIImageView = UIImageView()
    
    private let characterImageView: UIImageView = UIImageView()
    private let logoImageView: UIImageView = UIImageView()
    private lazy var logoStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [characterImageView, logoImageView])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        view.addSubViews(backgroundImageView, logoStackView)
        
        backgroundImageView.image = UIImage.splashBG
        logoImageView.image = UIImage.imgAtcha
        characterImageView.image = UIImage.imgAtchaCharacter
        characterImageView.tintColor = .main
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        logoStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    private func setupBindings() {
        viewModel.$appVersionInfo
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] versionInfo in
                guard let self else { return }
                updateAppVersion(versionInfo)
            }
            .store(in: &cancellables)
    }
    
    private func updateAppVersion(_ version: String) {
            let serverVersion = version
            let appVersion = AppInfoProvider.versionWithV
            
            // 서버 버전이 앱 버전보다 높다면 업데이트가 필요한 상황
            if isVersion(appVersion, lessThan: serverVersion) {
                showUpdatePopup(isEssential: false)
            } else {
                viewModel.makeInitialFlow()
            }
        }
    
    /// lhs < rhs 인지 비교 (서버 버전 < 앱 버전?)
    private func isVersion(_ lhs: String, lessThan rhs: String) -> Bool {
        let l = lhs.versionComponents()
        let r = rhs.versionComponents()
        let count = max(l.count, r.count)
        
        for i in 0..<count {
            let lv = i < l.count ? l[i] : 0
            let rv = i < r.count ? r[i] : 0
            if lv < rv { return true }
            if lv > rv { return false }
        }
        return false
    }
    
    private func showUpdatePopup(isEssential: Bool) {
            // 1. 팝업 뷰모델 생성 (info 타입은 프로젝트 정의에 맞게 조절하세요)
            let popupVM = AtchaPopupViewModel(info: isEssential ? .update_essential : .update_recommended)
            let popupVC = AtchaPopupViewController(viewModel: popupVM)
            
            // 2. [업데이트하기] 버튼 로직
            popupVC.confirmButton.addAction(UIAction { _ in
                let appID = "6747877903"
                if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)"),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }, for: .touchUpInside)
            
            // 3. [닫기/취소] 버튼 로직
            popupVC.cancelButton.addAction(UIAction { [weak self, weak popupVC] _ in
                popupVC?.dismiss(animated: false)
                
                if isEssential {
                    print("필수 업데이트입니다. 진행할 수 없습니다.")
                } else {
                    self?.viewModel.makeInitialFlow()
                }
            }, for: .touchUpInside)
            
            popupVC.modalPresentationStyle = .overFullScreen
            present(popupVC, animated: false)
        }
}
