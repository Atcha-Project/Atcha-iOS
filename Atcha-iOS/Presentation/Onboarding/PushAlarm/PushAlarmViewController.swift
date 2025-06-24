//
//  PushAlarmViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import UIKit
import SnapKit

struct AlarmOption {
    let title: String
    var isSelected: Bool
}

class PushAlarmViewController: BaseViewController<PushAlarmViewModel> {
    
    private let topNavigationBar: TitleNavigationBar = AtchaNavigationBar.title("")
    private let titleLabel: UILabel = UILabel()
    private let subTitleLabel: UILabel = UILabel()
    private var alarmOptions: [AlarmOption] = [
        .init(title: "5분 전", isSelected: true),
        .init(title: "10분 전", isSelected: false),
        .init(title: "20분 전", isSelected: true),
        .init(title: "30분 전", isSelected: false),
        .init(title: "1시간 전", isSelected: false)
    ]
    private let alarmListStackView: UIStackView = UIStackView()
    private var selectedStatusList: [Bool] = []
    private let nextButton: AtchaButton = AtchaButton(text: "다음", size: ButtonSize.h52, style: .filled(.primary)) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAlarmLists()
    }
    
    // MARK: - Push Alarm UI
    private func setupUI() {
        topNavigationBar.hideCloseButton()
        
        titleLabel.attributedText = AtchaFont.H3_B_22("막차 푸시 알림을 설정해요", color: AtchaColor.white)
        subTitleLabel.attributedText = AtchaFont.Body_R_15("출발지에서 막차 타는 곳까지\n시간 내에 걸어갈 수 있게 알람 드려요.", color: AtchaColor.gray200)
        subTitleLabel.numberOfLines = 0
        
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 12
        labelStack.alignment = .leading
        
        alarmListStackView.axis = .vertical
        alarmListStackView.axis = .vertical
        alarmListStackView.spacing = 0
        alarmListStackView.alignment = .fill
        alarmListStackView.distribution = .equalSpacing
        
        view.addSubViews(topNavigationBar, labelStack, alarmListStackView, nextButton)
        
        topNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        labelStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(72)
            make.leading.equalTo(view.snp.leading).inset(16)
        }
        
        alarmListStackView.snp.makeConstraints { make in
            make.top.equalTo(labelStack.snp.bottom).offset(44)
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
        // 1분 전 텍스트만 있는 리스트 추가
        let oneMinuteList = AtchaList(title: "1분 전", listType: .text("1분 전 푸시 알림은 무조건 드려요"))
        oneMinuteList.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
        alarmListStackView.addArrangedSubview(oneMinuteList)
        
        alarmOptions.forEach { option in
            let listView = AtchaList(title: option.title, listType: .checkmark(isOn: option.isSelected))
            listView.snp.makeConstraints { make in
                make.height.equalTo(52)
            }
            alarmListStackView.addArrangedSubview(listView)
        }
    }
    
}
