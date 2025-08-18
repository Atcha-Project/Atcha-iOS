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
    var onSelect: ((AtchaList) -> Void)?
    
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
        case .radioButton(let isOn):
            addRadioButtonView(isOn: isOn)
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
    
    @objc private func checkmarkTapped() {
        switch listType {
        case .radioButton:
            if checkmarkIsOn { onSelect?(self); return }
            setRadio(true)
            onSelect?(self)

        case .checkmark:
            checkmarkIsOn.toggle()
            guard let iv = checkmarkImageView else { return }
            UIView.transition(with: iv, duration: 0.25, options: .transitionCrossDissolve) { [weak self] in
                guard let self else { return }
                iv.tintColor = self.checkmarkIsOn ? .main : .gray700
            }
            onSelect?(self)

        default:
            break
        }
    }

    
    func setCheckmark(_ isOn: Bool) {
        checkmarkIsOn = isOn
        checkmarkImageView?.tintColor = isOn ? .main : .gray700
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
}

// MARK: - CheckMark
extension AtchaList {
    private func addRadioButtonView(isOn: Bool = false) {
        let image = (isOn ? UIImage.radioOn : UIImage.radioOff).withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = isOn ? .main : .gray400
        
        rightView.addSubview(imageView)
        
        rightView.snp.remakeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        
        imageView.snp.makeConstraints { make in
            make.size.equalTo(20)
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        label.snp.remakeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
    
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(checkmarkTapped))
        addGestureRecognizer(tapGesture)
        checkmarkIsOn = isOn
        checkmarkImageView = imageView
    }
    
    func setRadio(_ isOn: Bool) {
        guard case .radioButton = listType else { return }
        checkmarkIsOn = isOn
        checkmarkImageView?.image = (isOn ? UIImage.radioOn : UIImage.radioOff).withRenderingMode(.alwaysTemplate)
        checkmarkImageView?.tintColor = isOn ? .main : .gray400
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
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
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
            make.height.equalTo(34)
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



