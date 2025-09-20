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
        
        guard let topMessage else {
            topLabel.isHidden = true
            return
        }
        topLabel.attributedText = AtchaFont.B7_M_13(topMessage, color: .white)
        topLabel.isHidden = false
    }
    
    func separationTitle(grayMessage: String, whiteMessage: String) {
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
}

