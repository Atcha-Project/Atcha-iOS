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
        let options = AlarmTimeOption.allCases
        let selectedAlarms = alarmCheckmarkLists.map { $0.isCheckmarkSelected() }
        
        let selectedOptions = zip(options, selectedAlarms)
            .enumerated()
            .compactMap { index, pair in
                let (option, isSelected) = pair
                return index == 0 || isSelected ? option : nil
            }
        
        self.viewModel.signUp(selectedAlarms: selectedOptions)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAlarmLists()
        setupAutoLayout()
    }
    
    // MARK: - Push Alarm UI
    private func setupUI() {
        view.addSubViews(topNavigationBar, titleLabel, pushImageView, alarmListStackView, nextButton)
        
        topNavigationBar.hideCloseButton()
        
        titleLabel.attributedText = AtchaFont.H2_B_22("출발 알람을 받기 전,\n푸시로 미리 알려드려요",
                                                      color: AtchaColor.white)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        
        pushImageView.image = UIImage.imgNotification
        pushImageView.contentMode = .scaleAspectFill
        
        alarmListStackView.axis = .vertical
        alarmListStackView.spacing = 0
        alarmListStackView.alignment = .fill
        alarmListStackView.distribution = .equalSpacing
    }
    
    private func setupAutoLayout() {
        topNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(72)
            make.leading.equalTo(view.snp.leading).inset(16)
        }
        
        pushImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        
        alarmListStackView.snp.makeConstraints { make in
            make.top.equalTo(pushImageView.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview()
        }
        
        nextButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
        }
    }
    
    // MARK: - 알림 리스트 UI
    private func setupAlarmLists() {
        AlarmTimeOption.allCases.enumerated().forEach { index, alarm in
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
