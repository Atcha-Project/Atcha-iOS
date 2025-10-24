//
//  AtchaBallon.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/26/25.
//

import UIKit
import SnapKit

final class AtchaBallon: UIView {
    private let topLabel: AtcahaInsetLabel = AtcahaInsetLabel()
    private let bottomLabel: AtcahaInsetLabel = AtcahaInsetLabel()
    private let triangeImageView: UIImageView = UIImageView()
    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [topLabel, bottomLabel])
        stackView.axis = .vertical
        stackView.spacing = 5
        stackView.alignment = .leading
        return stackView
    }()
    private lazy var labels: [UILabel] = [topLabel, bottomLabel]
    
    init() {
        super.init(frame: .zero)
        
        setupUI()
        setupTriangleView()
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubViews(containerStackView, triangeImageView)
        
        labels.forEach { label in
            label.textAlignment = .left
            label.numberOfLines = 0
            label.backgroundColor = UIColor.gray950
            label.layer.cornerRadius = 10
            label.clipsToBounds = true
        }
        
        triangeImageView.image = UIImage.triangle
        triangeImageView.contentMode = .scaleAspectFit
    }
    
    
    private func setupTriangleView() {
        triangeImageView.image = UIImage.triangle
        triangeImageView.contentMode = .scaleAspectFit
    }
    
    private func setupAutoLayout() {
        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        triangeImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(containerStackView.snp.bottom).inset(1)
            make.width.equalTo(10)
            make.height.equalTo(6)
        }
    }
    
    func setupTitle(topMessage: String? = nil, bottomMessage: String) {
        bottomLabel.attributedText = AtchaFont.B7_M_13(bottomMessage, color: .white)
        
        if let topMessage {
            topLabel.attributedText = AtchaFont.B7_M_13(topMessage, color: .white)
            topLabel.isHidden = false
        } else {
            topLabel.isHidden = true
        }
    }
    
    func separationTitle(grayMessage: String, whiteMessage: String, showTopLine: Bool) {
        if showTopLine {
            // 알람 등록 전: 위 줄 보이게 (고정 문구)
            topLabel.isHidden = false
            topLabel.attributedText = AtchaFont.B7_M_13("지도를 움직여 출발지를 설정해 봐요", color: .white)
            topLabel.alpha = 1
        } else {
            // 알람 등록 후: 위 줄 숨김
            topLabel.isHidden = true
            topLabel.attributedText = nil
            topLabel.alpha = 0
        }

        // 아래줄 구성 (택시비)
        let gray = NSMutableAttributedString(attributedString: AtchaFont.B7_M_13(grayMessage))
        gray.addAttributes([.foregroundColor: UIColor.gray100],
                           range: NSRange(location: 0, length: gray.length))
        let white = NSMutableAttributedString(attributedString: AtchaFont.B7_M_13(whiteMessage))
        white.addAttributes([.foregroundColor: UIColor.white],
                            range: NSRange(location: 0, length: white.length))

        let composed = NSMutableAttributedString()
        composed.append(gray)
        composed.append(white)
        bottomLabel.attributedText = composed
    }
    
    func animateStaggered(secondaryDelay: TimeInterval = 0.8, fade: TimeInterval = 0.25) {
        // 기존 애니메이션 정리
        layer.removeAllAnimations()
        topLabel.layer.removeAllAnimations()
        bottomLabel.layer.removeAllAnimations()
        triangeImageView.layer.removeAllAnimations()   // 삼각형도 초기화

        // 시작 상태
        if topLabel.isHidden {
            // 한 줄만 사용하는 경우: 아래줄 + 삼각형 같이 페이드인
            bottomLabel.alpha = 0
            triangeImageView.alpha = 0
            UIView.animate(withDuration: fade) {
                self.bottomLabel.alpha = 1
                self.triangeImageView.alpha = 1
            }
        } else {
            // 두 줄 사용하는 경우: 위 줄 먼저 -> (secondaryDelay) -> 아래줄 + 삼각형
            topLabel.alpha = 0
            bottomLabel.alpha = 0
            triangeImageView.alpha = 0

            UIView.animate(withDuration: fade) {
                self.topLabel.alpha = 1
            }

            UIView.animate(withDuration: fade, delay: secondaryDelay, options: .curveEaseInOut) {
                self.bottomLabel.alpha = 1
                self.triangeImageView.alpha = 1
            }
        }
    }
    
    func revealImmediately() {
            topLabel.alpha = 1
            bottomLabel.alpha = 1
            triangeImageView.alpha = 1
        }
}

