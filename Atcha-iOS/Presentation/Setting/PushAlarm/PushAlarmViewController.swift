//
//  PushAlarmViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import UIKit
import SnapKit
import AVFAudio

final class PushAlarmViewController: BaseViewController<PushAlarmViewModel> {
    private lazy var topNavigationBar: TitleNavigationBar = AtchaNavigationBar.title(onBack: { [weak self] in
        guard let self else { return }
        AlarmManager.shared.stopPreview()
        navigationController?.popViewController(animated: true)
    })
    
    private let titleLabel: UILabel = UILabel()
    private let alarmListStackView: UIStackView = UIStackView()
    private var alarmCheckmarkLists: [AtchaList] = []
    private var selectedOption: PushAlarmOption?
    var onSettingComplete: ((Bool) -> Void)?
    private let settingBottomView: PushAlarmBottomView = PushAlarmBottomView()
    private lazy var nextButton: AtchaButton = AtchaButton(text: "설정 완료",
                                                           size: .h52,
                                                           style: .filled(.disabled)) { [weak self] in
        guard let self else { return }
        AlarmManager.shared.stopPreview()
        if let selectedOption = self.selectedOption {
            AlarmManager.shared.setAlarmOption(selectedOption)
        }
        AlarmManager.shared.setAlarmVolume(settingBottomView.getVolume())
        switch self.viewModel.context {
        case .onboarding:
            self.viewModel.signUp()
        case .myPage:
            self.onSettingComplete?(true)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindViewModel()
        setupAlarmLists()
        setupAutoLayout()
    }
    
    // MARK: - ViewModel 바인딩
    private func bindViewModel() {
        viewModel.$context
            .receive(on: RunLoop.main)
            .sink { [weak self] context in
                guard let self else { return }
                setupUI(context: context)
            }
            .store(in: &cancellables)
    }
    
    private func setupUI(context: PushAlarmContext) {
        switch context {
        case .onboarding:
            setupOnbaordingUI()
        case .myPage:
            setupMyPageUI()
        }
    }
    
    private func setupOnbaordingUI() {
        topNavigationBar.updateTitle("")
    }
    
    private func setupMyPageUI() {
        topNavigationBar.updateTitle("알람 설정")
    }
    
    // MARK: - Push Alarm 기본 UI
    private func setupUI() {
        view.addSubViews(topNavigationBar, titleLabel, alarmListStackView, settingBottomView, nextButton)
        topNavigationBar.hideCloseButton()
        
        titleLabel.attributedText = AtchaFont.H2_B_22("출발 알람 받을 방법을\n설정해주세요",
                                                      color: AtchaColor.white)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        
        alarmListStackView.axis = .vertical
        alarmListStackView.spacing = 0
        alarmListStackView.alignment = .fill
        alarmListStackView.distribution = .fill
        
        settingBottomView.isHidden = true
    }
    
    private func setupAutoLayout() {
        topNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(topNavigationBar.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
        }
        
        alarmListStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualTo(nextButton.snp.top).offset(-341)
        }
        
        settingBottomView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(214)
        }
        
        nextButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(40)
        }
    }
    
    // MARK: - 알림 리스트 UI
    private func setupAlarmLists() {
        let preselectOption: PushAlarmOption? = (viewModel.context == .myPage)
        ? AlarmManager.shared.selectedOption
        : nil
        
        PushAlarmOption.allCases.enumerated().forEach { index, option in
            let isSelected = (option == preselectOption)
            
            let listView = AtchaList(
                title: option.rawValue,
                listType: .radioButton(isOn: isSelected)
            )
            listView.onSelect = { [weak self] selected in
                guard let self else { return }
                
                self.alarmCheckmarkLists.forEach { $0.setRadio(false) }
                selected.setRadio(true)
                
                self.selectedOption = option
                self.nextButton.updateStyle(text: "설정 완료", style: .filled(.primary))
                
                AlarmManager.shared.stopPreview()
                AlarmManager.shared.setAlarmOption(option)
                
                switch option {
                case .onlyVibration:
                    self.toggleBottomView(show: false)
                    AlarmManager.shared.previewAlarmVolume(0)  // 진동만 테스트
                    
                case .onlySound:
                    self.toggleBottomView(show: true)
                    AlarmManager.shared.previewAlarmVolume(0.7)
                    
                case .both:
                    self.toggleBottomView(show: true)
                    AlarmManager.shared.previewAlarmVolume(0.7)
                }
            }
            
            listView.snp.makeConstraints { make in
                make.height.equalTo(52)
            }
            alarmListStackView.addArrangedSubview(listView)
            alarmCheckmarkLists.append(listView)
        }
    }
    
    private func toggleBottomView(show: Bool) {
        if show {
            settingBottomView.isHidden = false
        } else {
            settingBottomView.isHidden = true
        }
    }
}

