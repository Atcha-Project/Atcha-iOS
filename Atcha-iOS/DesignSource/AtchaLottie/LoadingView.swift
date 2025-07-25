//
//  LoadingView.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/26/25.
//

import UIKit
import SnapKit
import Lottie

final class LoadingView: UIView {
    
    private let animationView: LottieAnimationView = {
        let animView = LottieAnimationView(name: "Loading")
        animView.loopMode = .loop
        animView.contentMode = .scaleAspectFit
        animView.translatesAutoresizingMaskIntoConstraints = false
        return animView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        animationView.play()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        addSubview(animationView)
        
        animationView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    func start() {
        animationView.play()
    }
    
    func stop() {
        animationView.stop()
        removeFromSuperview()
    }
}
