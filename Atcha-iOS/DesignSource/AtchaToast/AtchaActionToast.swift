//
//  AtchaActionToast.swift
//  Atcha-iOS
//
//  Created by wodnd on 1/9/26.
//

import Foundation
import UIKit
import SnapKit

final class AtchaActionToast: UIView {

    private let messageLabel = UILabel()
    private let actionLabel = UILabel()
    private var action: (() -> Void)?

    private var dismissWorkItem: DispatchWorkItem?
    
    init(message: String, actionTitle: String, action: @escaping () -> Void) {
        super.init(frame: .zero)
        self.action = action

        setupLabel(message: message)
        setupActionLabel(title: actionTitle)
        setupView()
        setupLayout()
        setupTapGesture()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupLabel(message: String) {
        messageLabel.attributedText = AtchaFont.B4_R_15(message, color: .white)
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .left
        addSubview(messageLabel)
    }

    private func setupActionLabel(title: String) {
        actionLabel.attributedText = AtchaFont.B4_R_15(title, color: AtchaColor.main)
        actionLabel.numberOfLines = 1
        actionLabel.textAlignment = .right
        addSubview(actionLabel)

        // 레이아웃 안정화
        actionLabel.setContentHuggingPriority(.required, for: .horizontal)
        actionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setupView() {
        backgroundColor = .gray930
        layer.cornerRadius = 12
        clipsToBounds = true
        isUserInteractionEnabled = true
    }

    private func setupLayout() {
        messageLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(actionLabel.snp.leading).offset(-8)
        }

        actionLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        // 토스트 최소 높이 (터치 영역)
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(52)
        }
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapToast))
        tap.cancelsTouchesInView = true
        addGestureRecognizer(tap)
    }

    @objc private func didTapToast() {
        action?()
        hideImmediately()
    }
}

extension AtchaActionToast {
    func show(in parentView: UIView,
              duration: TimeInterval = 2.0,
              topOffset: CGFloat = 10) {

        if superview != nil {
            dismissWorkItem?.cancel()
            scheduleDismiss(after: duration)
            return
        }

        let container = parentView.window ?? parentView
        container.addSubview(self)
        container.bringSubviewToFront(self)
        layer.zPosition = 9999

        snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            if let window = container as? UIWindow {
                make.top.equalTo(window.safeAreaLayoutGuide.snp.top).offset(topOffset)
            } else {
                make.top.equalTo(container.safeAreaLayoutGuide.snp.top).offset(topOffset)
            }
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.greaterThanOrEqualTo(52)
        }

        container.layoutIfNeeded()

        alpha = 0.0
        transform = CGAffineTransform(translationX: 0, y: -10)

        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                self.alpha = 1.0
                self.transform = .identity
            },
            completion: { _ in
                self.scheduleDismiss(after: duration)
            }
        )
    }

    private func scheduleDismiss(after duration: TimeInterval) {
        dismissWorkItem?.cancel()

        let work = DispatchWorkItem { [weak self] in
            self?.hideAnimated()
        }
        dismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

    private func hideAnimated() {
        // 퇴장 애니메이션
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseIn, .allowUserInteraction],
            animations: {
                self.transform = CGAffineTransform(translationX: 0, y: -100)
            },
            completion: { _ in
                self.removeFromSuperview()
            }
        )
    }

    func hideImmediately() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        layer.removeAllAnimations()
        removeFromSuperview()
    }
}
