//
//  SplashViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import UIKit
import SnapKit

final class SplashViewController: UIViewController {
    private let backgroundImageView: UIImageView = UIImageView()
    private let appLogoImageView: UIImageView = UIImageView()
    
    private let viewModel: SplashViewModel
    
    init(viewModel: SplashViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindViewModel()
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
    
    private func bindViewModel() {
        
    }
}
