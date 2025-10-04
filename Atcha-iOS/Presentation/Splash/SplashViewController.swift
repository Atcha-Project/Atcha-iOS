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
        viewModel.makeInitialFlow()
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
            make.centerX.equalTo(view.safeAreaLayoutGuide)
            make.centerY.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func setupBindings() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { isLoading in
                // 로딩 UI 표시/숨김
                print("isLoading: \(isLoading)")
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { message in
                // Alert 띄우기
                print("Error: \(message)")
            }
            .store(in: &cancellables)
        
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
        let severVersion: String = version
        let appVersion: String = AppInfoProvider.versionWithV
        
        if isVersion(severVersion, lessThan: appVersion) {
            viewModel.updateAppVersion(version: appVersion)
        } else {
            print("강제 업데이트 표출해주세요!!")
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
}
