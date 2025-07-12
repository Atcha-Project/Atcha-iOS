//
//  LockViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/30/25.
//

import UIKit
import SnapKit
import Lottie

final class LockViewController: BaseViewController<LockViewModel> {

    private let backgroundImageView: UIImageView = UIImageView()
    private let logoImageView: UIImageView = UIImageView()
    private let titleLabel: UILabel = UILabel()
    private let taxiFareLabel: UILabel = UILabel()
    private let startButton: AtchaButton = AtchaButton(text: "출발하기", size: .h52, style: .filled(.primary)) {
        
    }
    private let detailRouteButton: AtchaButton = AtchaButton(text: "더 늦은 경로 확인하기", size: .h52, style: .filled(.opacity)) {
        
    }
    private let bottomStack: UIStackView = UIStackView()
    private var lottieAnimationView: LottieAnimationView = LottieAnimationView()
    private let gradientView: UIView = UIView()
    private let gradient: CAGradientLayer = CAGradientLayer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        bind()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = gradientView.bounds
    }
    
    // MARK: - ViewModel 바인딩
    private func bind() {
        viewModel.$taxiFare
            .map { $0.formattedWithComma }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stringFare in
                self?.taxiFareLabel.attributedText = AtchaFont.D1_EB_56("-\(stringFare)", color: AtchaColor.Bus.widearea)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Lock UI
    private func setupUI() {
        backgroundImageView.image = UIImage.lockBackground
        lottieAnimationView = LottieAnimationView(name: "잠금화면")
        lottieAnimationView.contentMode = .scaleAspectFit
        lottieAnimationView.loopMode = .loop
        lottieAnimationView.play()
        
        gradient.colors = [
            UIColor.black.cgColor,
            UIColor.clear.cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientView.layer.addSublayer(gradient)
        
        logoImageView.image = UIImage.atchaMain
        titleLabel.attributedText = AtchaFont.H2_B_22("지금 안 일어나면\n택시비", color: AtchaColor.white)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        bottomStack.addArrangedSubview(startButton)
        bottomStack.addArrangedSubview(detailRouteButton)
        bottomStack.axis = .vertical
        bottomStack.spacing = 12
        
        view.addSubViews(backgroundImageView, lottieAnimationView, gradientView, logoImageView, titleLabel, taxiFareLabel, bottomStack)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        lottieAnimationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        gradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(104)
            make.size.equalTo(36)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoImageView.snp.bottom).offset(28)
        }
        
        taxiFareLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
        }
        
        bottomStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(32)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().inset(20)
        }
    }
}
