//
//  RefreshView.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/4/25.
//

import UIKit
import SnapKit
import Lottie

final class RefreshView: UIView {
    
    private let animationView: LottieAnimationView = {
        let animView = LottieAnimationView(name: "Refresh")
        animView.loopMode = .playOnce
        animView.contentMode = .scaleAspectFit
        animView.translatesAutoresizingMaskIntoConstraints = false
        return animView
    }()
    private let refreshImageView: UIImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
        animationView.play()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        animationView.contentMode = .scaleAspectFit
        refreshImageView.image = UIImage.refreshBackground
        refreshImageView.contentMode = .scaleAspectFit
        
        addSubViews(refreshImageView, animationView)
    }
    
    private func setupAutoLayout() {
        refreshImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        animationView.snp.makeConstraints { make in
            make.center.equalTo(refreshImageView)
            make.size.equalTo(24)
        }
    }
    
    func start() {
        animationView.play()
    }
    
    func stop() {
        animationView.stop()
    }
}
