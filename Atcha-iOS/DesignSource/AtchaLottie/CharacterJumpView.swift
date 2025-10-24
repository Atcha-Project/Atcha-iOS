//
//  CharacterJumpView.swift
//  Atcha-iOS
//
//  Created by wodnd on 10/23/25.
//

import UIKit
import SnapKit
import Lottie

final class CharacterJumpView: UIView {

    private let animationView: LottieAnimationView = {
        let v = LottieAnimationView(name: "Character_Jump")
        v.loopMode = .playOnce
        v.contentMode = .scaleAspectFit
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(autoPlay: Bool = false) {
        super.init(frame: .zero)
        setupUI()
        setupAutoLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        animationView.contentMode = .scaleAspectFit
        addSubViews(animationView)
    }

    private func setupAutoLayout() {
        animationView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(64)
        }
    }

    // 애니메이션 컨트롤만 공개
    func start() { animationView.play() }
    func stop()  { animationView.stop() }
}

