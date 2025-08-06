//
//  PushAlarmViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import UIKit
import SnapKit

final class PushAlarmViewController: BaseViewController<PushAlarmViewModel> {
    private lazy var topNavigationBar: TitleNavigationBar = AtchaNavigationBar.title(onBack: { [weak self] in
        guard let self else { return }
        navigationController?.popViewController(animated: true)
    })
    
    private let titleLabel: UILabel = UILabel()
    private let pushImageView: UIImageView = UIImageView()
    
    private let alarmListStackView: UIStackView = UIStackView()
    private var alarmCheckmarkLists: [AtchaList] = []
    private lazy var nextButton: AtchaButton = AtchaButton(text: "다음",
                                                           size: .h52,
                                                           style: .filled(.primary)) { [weak self] in
        guard let self else { return }
        let options = AlarmTimeOption.displayOptions
        let selectedAlarms = alarmCheckmarkLists.map { $0.isCheckmarkSelected() }
        
        let selectedOptions = zip(options, selectedAlarms)
            .compactMap { option, isSelected in
                isSelected ? option : nil
            }
        
        let finalOptions: [AlarmTimeOption] = [.oneMinute] + selectedOptions
        
        switch self.viewModel.context {
        case .onboarding:
            self.viewModel.signUp(selectedAlarms: finalOptions)
        case .myPage:
            Task {
                do {
                    try await self.viewModel.pushAlarmPatch(selectedAlarms: finalOptions)
                    AtchaToast(message: "푸시 알림 설정이 변경되었어요").show(in: self.view)
                } catch {
                    AtchaToast(message: "푸시 알림 설정에 실패했어요").show(in: self.view)
                }
                self.alarmCheckmarkLists.forEach { $0.setCheckmark(false) }
            }
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
        view.addSubViews(titleLabel, pushImageView)
        titleLabel.attributedText = AtchaFont.H2_B_22("출발 알람을 받기 전,\n푸시로 미리 알려드려요",
                                                      color: AtchaColor.white)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        
        pushImageView.image = UIImage.imgNotification
        pushImageView.contentMode = .scaleAspectFill
        
        topNavigationBar.updateTitle("")
        nextButton.updateStyle(text: "확인", style: .filled(.primary))
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(72)
            make.leading.equalTo(view.snp.leading).inset(16)
        }
        
        pushImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        
        alarmListStackView.snp.remakeConstraints { make in
            make.top.equalTo(pushImageView.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualTo(nextButton.snp.top).offset(-155.12)
        }
    }
    
    private func setupMyPageUI() {
        view.addSubViews(titleLabel)
        
        titleLabel.attributedText = AtchaFont.B4_R_15(lineHeight: 0, "출발 알림을 받기 전, 푸시로 미리 알려드려요", color: AtchaColor.white)
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .left
        
        topNavigationBar.updateTitle("푸시 알림 설정")
        nextButton.updateStyle(text: "저장", style: .filled(.primary))
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(topNavigationBar.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
        }
        
        alarmListStackView.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(36)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualTo(nextButton.snp.top).offset(-253)
        }
    }
    
    // MARK: - Push Alarm 기본 UI
    private func setupUI() {
        view.addSubViews(topNavigationBar, alarmListStackView, nextButton)
        topNavigationBar.hideCloseButton()
        
        alarmListStackView.axis = .vertical
        alarmListStackView.spacing = 0
        alarmListStackView.alignment = .fill
        alarmListStackView.distribution = .fill
    }
    
    private func setupAutoLayout() {
        topNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        alarmListStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }
        
        nextButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(40)
        }
    }
    
    // MARK: - 알림 리스트 UI
    private func setupAlarmLists() {
        AlarmTimeOption.displayOptions.enumerated().forEach { index, alarm in
            let listView: AtchaList
            switch index {
            default:
                listView = AtchaList(title: alarm.title, listType: .checkmark(isOn: false))
            }
            listView.snp.makeConstraints { make in
                make.height.equalTo(52)
            }
            
            alarmListStackView.addArrangedSubview(listView)
            alarmCheckmarkLists.append(listView)
        }
    }
}

