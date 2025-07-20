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
//        viewModel.checkAppVersion()
//        viewModel.makeInitialFlow()
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
            .sink { versionInfo in
                print("App Version Info: \(versionInfo)")
                // 버전에 따른 로직 처리
            }
            .store(in: &cancellables)
    }
}
