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
    enum Background {
        case `default`   // 기본 배경 노출
        case hidden      // 배경 숨김
    }

    private let animationView: LottieAnimationView = {
        let v = LottieAnimationView(name: "Refresh")
        v.loopMode = .playOnce
        v.contentMode = .scaleAspectFit
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let refreshImageView = UIImageView()

    init(background: Background = .default, autoPlay: Bool = false) {
        super.init(frame: .zero)
        setupUI()
        setupAutoLayout()
        apply(background)
        if autoPlay { animationView.play() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        refreshImageView.contentMode = .scaleAspectFit
        animationView.contentMode = .scaleAspectFit
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

    // 내부 적용 로직 (공개 메서드 아님)
    private func apply(_ state: Background) {
        switch state {
        case .default:
            refreshImageView.isHidden = false
            refreshImageView.image = UIImage.refreshBackground
        case .hidden:
            refreshImageView.isHidden = true
            refreshImageView.image = nil
        }
    }

    // 애니메이션 컨트롤만 공개
    func start() { animationView.play() }
    func stop()  { animationView.stop() }
}

