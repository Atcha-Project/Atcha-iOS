//
//  AtchaList.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/18/25.
//

import UIKit
import SnapKit

class AtchaList: UIView {
    private var optionTitle: String = ""
    private var listType: AtchaListType
    private var checkmarkIsOn: Bool = false
    private var checkmarkImageView: UIImageView?
    
    private let label = UILabel()
    private let rightView = UIView()
    private var actionButton: UIButton?
    
    init(title: String, listType: AtchaListType) {
        self.listType = listType
        self.optionTitle = title
        super.init(frame: .zero)
        
        setupLabel(title: title)
        setupRightView()
        setupAutoLayout()
        configure(title: title, type: listType)
        
        backgroundColor = UIColor.gray950
    }
    
    required init?(coder: NSCoder) {
        self.listType = .none
        super.init(coder: coder)
    }
    
    private func setupLabel(title: String) {
        label.textColor = .white
        label.attributedText = AtchaFont.B4_R_15(title, color: .white)
        label.lineBreakMode = .byTruncatingTail
        addSubview(label)
    }
    
    private func setupRightView() {
        addSubview(rightView)
        rightView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    private func setupAutoLayout() {
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        rightView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(label.snp.trailing).offset(10)
        }
    }
    
    private func configure(title: String, type: AtchaListType) {
        switch type {
        case .checkmark(let isOn):
            addCheckmarkView(isOn: isOn)
        case .text(let text):
            addTextLabelView(text: text)
        case .arrow:
            addArrowView()
        case .button(let title, let action):
            addButtonView(title: title, onTap: action)
        case .none: break
        }
    }
    
    func isCheckmarkSelected() -> Bool {
        if case .checkmark = listType {
            return checkmarkIsOn
        }
        return false
    }
    
    
    func getTitle() -> String {
        return optionTitle
    }
}

// MARK: - CheckMark
extension AtchaList {
    private func addCheckmarkView(isOn: Bool = false) {
        let image = UIImage.check.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = isOn ? .main : .gray700
        
        rightView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.size.equalTo(20)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(checkmarkTapped))
        addGestureRecognizer(tapGesture)
        checkmarkIsOn = isOn
        checkmarkImageView = imageView
    }
    
    @objc private func checkmarkTapped() {
        checkmarkIsOn.toggle()
        UIView.transition(with: checkmarkImageView!,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            guard let self else { return }
            checkmarkImageView?.tintColor = checkmarkIsOn ? .main : .lightGray
        }, completion: nil)
    }
}

// MARK: - Text
extension AtchaList {
    private func addTextLabelView(text: String) {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 1
        label.attributedText = AtchaFont.B6_R_14(text, color: .gray400)
        
        rightView.addSubview(label)
        label.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - Arrow
extension AtchaList {
    private func addArrowView() {
        let image = UIImage.chevronRight.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = .gray400
        
        rightView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.size.equalTo(16)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - Button
extension AtchaList {
    private func addButtonView(title: String, onTap: (() -> Void)?) {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor.gray910
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        config.cornerStyle = .medium
        config.title = title
        
        let button = UIButton(configuration: config)
        button.configurationUpdateHandler = { button in
            var updatedConfig = button.configuration
            let attributes = AttributeContainer([.font: UIFont(name: AtchaFont.Pretendard.Medium.rawValue, size: 14)!])
            updatedConfig?.attributedTitle = AttributedString(title, attributes: attributes)
            button.configuration = updatedConfig
        }
        addSubview(button)
        
        label.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(button.snp.leading).offset(-8)
        }
        button.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        actionButton = button
        if let onTap {
            button.addAction(UIAction { [weak self] _ in
                guard let _ = self else { return }
                onTap()
            }, for: .touchUpInside)
        }
    }
}



