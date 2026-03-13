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
        setupGesture()
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
        self.isUserInteractionEnabled = true
    }
    
    private func setupAutoLayout() {
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        }
    }
    
    private func setupGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        self.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        let velocity = gesture.velocity(in: self.superview)
        
        switch gesture.state {
        case .began:
            // 중요: 자동 사라짐 예약 취소!
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autoHide), object: nil)
            self.layer.removeAllAnimations()
            
        case .changed:
            if translation.y < 0 {
                self.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
            
        case .ended:
            if translation.y < -30 || velocity.y < -500 {
                dismissWithAnimation()
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction], animations: {
                    self.transform = .identity
                }) { _ in
                    // 다시 제자리로 왔으니 자동 사라짐 재예약 (선택 사항)
                    self.perform(#selector(self.autoHide), with: nil, afterDelay: 2.0)
                }
            }
        default: break
        }
    }
    
    // 공통 삭제 애니메이션
    // dismissWithAnimation에서도 안전하게 한 번 더 취소해주는 게 좋습니다.
    private func dismissWithAnimation() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autoHide), object: nil)
        self.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: -100)
        }) { _ in
            self.removeFromSuperview()
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
        
        // 초기 상태
        alpha = 0.0
        transform = CGAffineTransform(translationX: 0, y: -10)
        
        // 1. 등장 애니메이션 (사용자 터치 허용 옵션 추가)
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: [.beginFromCurrentState, .allowUserInteraction], // 터치 허용!
                       animations: {
            self.alpha = 1.0
            self.transform = .identity
        }) { _ in
            // 2. 일정 시간 뒤에 자동으로 사라지게 함 (애니메이션 내부 delay 대신 사용)
            // 이렇게 해야 대기 시간 동안 제스처가 먹습니다.
            self.perform(#selector(self.autoHide), with: nil, afterDelay: duration)
        }
    }

    @objc private func autoHide() {
        dismissWithAnimation()
    }
    
    // AtchaToast.swift 내부 수정

    func hideImmediately() {
        // 1. 예약된 autoHide 타이머를 즉시 취소 (가장 중요)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autoHide), object: nil)
        
        // 2. 현재 실행 중인 모든 레이어 애니메이션 중단
        self.layer.removeAllAnimations()
        
        // 3. 부모 뷰에서 즉시 제거
        self.removeFromSuperview()
        
        // 4. 터치 상태 초기화
        self.isUserInteractionEnabled = false
    }
}
