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
    private let appLogoImageView: UIImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        viewModel.checkAppVersion()
    }
    
    private func setupUI() {
        view.addSubViews(backgroundImageView, appLogoImageView)
        
        backgroundImageView.image = UIImage.imgSplash
        appLogoImageView.image = UIImage.imgAtcha
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        appLogoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
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
            .sink { versionInfo in
                print("App Version Info: \(versionInfo)")
                // 버전에 따른 로직 처리
            }
            .store(in: &cancellables)
    }
}
