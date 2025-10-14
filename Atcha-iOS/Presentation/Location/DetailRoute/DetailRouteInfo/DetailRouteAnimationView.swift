//
//  DetailRouteAnimationView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 9/7/25.
//

import UIKit

final class DetailRouteAnimationView: UIView {
    enum Const {
        static let smallCircleSize: CGFloat = 30
        static let largeCircleSize: CGFloat = 60
        static let duration: CFTimeInterval = 2.0
    }
    
    private let smallCircleView = UIView()
    private var isAnimating = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupAutoLayout()
        bindAppLifecycle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupAutoLayout()
        bindAppLifecycle()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Lifecycle hooks
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startAnimationIfNeeded()
        } else {
            stopAnimation()
        }
    }
    
    // MARK: - Setup
    private func setupView() {
        addSubview(smallCircleView)
        smallCircleView.backgroundColor = .systemGray5
        
        smallCircleView.layer.cornerRadius = Const.smallCircleSize / 2.0
        smallCircleView.clipsToBounds = true
    }
    
    private func setupAutoLayout() {
        smallCircleView.snp.makeConstraints { make in
            make.size.equalTo(Const.smallCircleSize)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    private func bindAppLifecycle() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        // 포어그라운드 복귀 시 안전하게 재시작
        startAnimationIfNeeded(forceRestart: true)
    }
    
    @objc private func appWillResignActive() {
        // 백그라운드 진입 전에 깔끔히 정지
        stopAnimation()
    }
    
    // MARK: - Animation (Core Animation 추천)
    
    func startAnimationIfNeeded(forceRestart: Bool = false) {
        guard window != nil else { return }
        
        if forceRestart { stopAnimation() }
        guard !isAnimating else { return }
        isAnimating = true
        
        // 맥박(확대 + 페이드아웃) 애니메이션: smallCircleView만 사용
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.0
        scale.toValue = Const.largeCircleSize / Const.smallCircleSize
        
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1.0
        fade.toValue = 0.0
        
        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = Const.duration
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards
        
        smallCircleView.layer.opacity = 1.0
        smallCircleView.layer.transform = CATransform3DIdentity
        smallCircleView.layer.add(group, forKey: "pulse")
    }
    
    func stopAnimation() {
        isAnimating = false
        smallCircleView.layer.removeAnimation(forKey: "pulse")
        // 상태 초기화
        smallCircleView.layer.opacity = 1.0
        smallCircleView.layer.transform = CATransform3DIdentity
    }
}
