//
//  PushAlarmViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import UIKit
import SnapKit

final class PushAlarmViewController: BaseViewController<PushAlarmViewModel> {
    private lazy var topNavigationBar: TitleNavigationBar = AtchaNavigationBar.title(onClose: { [weak self] in
        guard let self else { return }
        navigationController?.popViewController(animated: true)
    })
    
    private let titleLabel: UILabel = UILabel()
    private let subTitleLabel: UILabel = UILabel()
    private lazy var titleStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        return stack
    }()
    
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAlarmLists()
        setupAutoLayout()
    }
    
    // MARK: - Push Alarm UI
    private func setupUI() {
        view.addSubViews(topNavigationBar, titleStackView, alarmListStackView, nextButton)
        
        topNavigationBar.hideCloseButton()
        
        titleLabel.attributedText = AtchaFont.H2_B_22("막차 푸시 알림을 설정해요",
                                                      color: AtchaColor.white)
        subTitleLabel.attributedText = AtchaFont.B4_R_15("출발지에서 막차 타는 곳까지\n시간 내에 걸어갈 수 있게 알람 드려요.",
                                                         color: AtchaColor.gray200)
        subTitleLabel.numberOfLines = 0
        
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
        
        titleStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(72)
            make.leading.equalTo(view.snp.leading).inset(16)
        }
        
        alarmListStackView.snp.makeConstraints { make in
            make.top.equalTo(titleStackView.snp.bottom).offset(44)
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
            case 0:
                listView = AtchaList(title: alarm.title, listType: .text("1분 전 푸시 알림은 무조건 드려요"))
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
