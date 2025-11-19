//
//  AtchaToast.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/18/25.
//

import UIKit
import SnapKit

final class AtchaToast: UIView {
    private let label = UILabel()
    
    init(message: String) {
        super.init(frame: .zero)
        
        setupLabel(message: message)
        setupView()
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabel(message: String) {
        label.text = message
        label.attributedText = AtchaFont.B4_R_15(message, color: .white)
        label.textAlignment = .left
        label.numberOfLines = 0
        addSubview(label)
    }
    
    private func setupView() {
        backgroundColor = UIColor.gray930
        layer.cornerRadius = 12
        clipsToBounds = true
    }
    
    private func setupAutoLayout() {
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        }
    }
}

extension AtchaToast {
    func show(in parentView: UIView,
              duration: TimeInterval = 2.0,
              topOffset: CGFloat = 10) {
        
        guard self.superview == nil else { return }
        
        parentView.addSubview(self)
        
        snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(parentView.safeAreaLayoutGuide.snp.top).offset(topOffset)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
        
        parentView.layoutIfNeeded()
        
        alpha = 0.0
        transform = CGAffineTransform(translationX: 0, y: -10)
        
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseOut],
                       animations: { [weak self] in
            guard let self else { return }
            alpha = 1.0
            transform = .identity
        }, completion: { _ in
            UIView.animate(withDuration: 0.8,
                           delay: duration,
                           options: [.curveEaseIn],
                           animations: { [weak self] in
                guard let self else { return }
                alpha = 1.0
                transform = CGAffineTransform(translationX: 0, y: -parentView.bounds.height)
            }, completion: { [weak self] _ in
                guard let self else { return }
                removeFromSuperview()
            })
        })
    }
    
    func hideImmediately() {
        layer.removeAllAnimations()
        removeFromSuperview()
    }
}
