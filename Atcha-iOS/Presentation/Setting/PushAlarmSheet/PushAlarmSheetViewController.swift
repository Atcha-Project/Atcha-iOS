//
//  PushAlarmSheetViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 3/4/26.
//

import UIKit
import SnapKit
import QuartzCore
import AVFAudio

final class PushAlarmSheetViewController: BaseViewController<PushAlarmSheetViewModel> {
    
    // MARK: - UI Components
    private let dimView = UIView()
    private let containerView = UIView()
    private let sheetHeight: CGFloat = 380
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.attributedText = AtchaFont.H2_B_22("알람 받을 방법을\n설정해 주세요")
        label.textColor = AtchaColor.white
        label.numberOfLines = 2
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private let alarmListStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private lazy var completeButton: AtchaButton = AtchaButton(
        text: "완료",
        size: .h52,
        style: .filled(.primary)
    )
    
    // MARK: - Properties
    private var alarmCheckmarkLists: [AtchaList] = []
    private var selectedOption: PushAlarmOption?
    
    // 화면이 닫혔을 때 코디네이터나 부모에게 알리기 위한 콜백
    var onDismiss: (() -> Void)?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        setupDim()
        setupUI()
        setupAutoLayout()
        setupAlarmLists()
        setupGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.dimView.alpha = 1
                self.containerView.transform = .identity
            }) { _ in
                AlarmManager.shared.previewAlarmVolume(0.3)
            }
        }
    
    deinit {
        AlarmManager.shared.stopPreview()
    }
    
    // MARK: - Setup Methods
    private func setupDim() {
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        dimView.alpha = 0
        view.addSubview(dimView)
    }
    
    private func setupUI() {
        containerView.backgroundColor = .gray940
        containerView.layer.cornerRadius = 24
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        
        view.backgroundColor = .clear
        containerView.addSubViews(titleLabel, closeButton, alarmListStackView, completeButton)
        
        // ✅ 버튼 타겟 설정
        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        completeButton.addTarget(self, action: #selector(didTapCompleteButton), for: .touchUpInside)
        
        // 초기 상태: 화면 아래에 숨김
        containerView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
    }
    
    private func setupAutoLayout() {
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(sheetHeight)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.equalToSuperview().inset(24)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().inset(24)
            make.width.height.equalTo(24)
        }
        
        alarmListStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview()
        }
        
        completeButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(40)
        }
    }
    
    private func setupAlarmLists() {
            // 이미지 순서: 소리 및 진동, 소리, 진동
            let options: [PushAlarmOption] = [.both, .onlySound, .onlyVibration]
            
            // 💡 기본 선택값을 .both로 강제 설정
            let currentOption = PushAlarmOption.both
            self.selectedOption = currentOption
            AlarmManager.shared.setAlarmOption(currentOption)
            
            options.forEach { option in
                let isSelected = (option == currentOption)
                let listView = AtchaList(
                    title: option.rawValue,
                    listType: .radioButton(isOn: isSelected)
                )
                
                listView.backgroundColor = isSelected ? AtchaColor.opacity100 : .clear
                
                listView.onSelect = { [weak self] selected in
                    guard let self = self else { return }
                    
                    self.alarmCheckmarkLists.forEach {
                        $0.setRadio(false)
                        $0.backgroundColor = .clear
                    }
                    selected.setRadio(true)
                    selected.backgroundColor = AtchaColor.opacity100
                    self.selectedOption = option
                    
                    // 💡 매니저의 옵션을 먼저 변경한 뒤 미리보기 호출
                    AlarmManager.shared.setAlarmOption(option)
                    AlarmManager.shared.previewAlarmVolume(0.3)
                }
                
                listView.snp.makeConstraints { $0.height.equalTo(52) }
                alarmListStackView.addArrangedSubview(listView)
                alarmCheckmarkLists.append(listView)
            }
        }
}

// MARK: - Actions
extension PushAlarmSheetViewController {
    
    // X 버튼 클릭 시 실행
    @objc private func didTapCloseButton() {
        AlarmManager.shared.stopPreview()
        dismissSheet()
    }
    
    // 완료 버튼 클릭 시 실행
    @objc private func didTapCompleteButton() {
        if let option = selectedOption {
            AlarmManager.shared.stopPreview()
            AlarmManager.shared.setAlarmOption(option)
            AlarmManager.shared.setAlarmArmed(true)
        }
        dismissSheet()
    }
}

// MARK: - Gestures & Animations
extension PushAlarmSheetViewController {
    private func setupGestures() {
        // 배경 터치 시 닫기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapDimView))
        dimView.addGestureRecognizer(tapGesture)
        dimView.isUserInteractionEnabled = true
        
        // 스와이프해서 닫기
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        containerView.addGestureRecognizer(panGesture)
    }
    
    @objc private func didTapDimView() {
        AlarmManager.shared.stopPreview()
        dismissSheet()
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended, .cancelled:
            if velocity.y > 1000 || translation.y > (sheetHeight / 2) {
                AlarmManager.shared.stopPreview()
                dismissSheet()
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                    self.containerView.transform = .identity
                })
            }
        default: break
        }
    }
    
    // 닫기 애니메이션 공통 로직
    private func dismissSheet() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.dimView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)
        }) { _ in
            self.dismiss(animated: false) {
                self.onDismiss?()
            }
        }
    }
}
