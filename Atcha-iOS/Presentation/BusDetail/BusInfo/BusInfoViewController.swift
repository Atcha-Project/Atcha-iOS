//
//  BusInfoViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/29/25.
//

import UIKit
import SnapKit

class BusInfoViewController: BaseViewController<BusInfoViewModel> {
    private lazy var topNavigationBar: IconTitleNavigationBar = {
        AtchaNavigationBar.iconTitle(
            viewModel.busNumber,
            viewModel.icon
        ) {
        } onClose: {
        }
    }()
    private let operationStationTitleLabel: UILabel = UILabel()
    private let stationStack: UIStackView = UIStackView()
    private let stationImageView: UIImageView = UIImageView()
    private let startStationLabel: UILabel = UILabel()
    private let endStationLabel: UILabel = UILabel()
    private let operationRegionLabel: UILabel = UILabel()
    
    private let operationTimeTitleLabel: UILabel = UILabel()
    private let operationTimeStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        
        // 🚨 테스트용 더미데이터 (실제로는 viewModel에서 주입)
        let mockServiceHours: [ServiceHours] = [
            // 평일 (WEEKDAY)
            ServiceHours(dailyType: "WEEKDAY", busDirection: "UP", startTime: "2025-07-30T04:30", endTime: "2025-07-30T23:00", term: 10),
            ServiceHours(dailyType: "WEEKDAY", busDirection: "DOWN", startTime: "2025-07-30T05:00", endTime: "2025-07-30T23:30", term: 12),

            // 토요일 (SATURDAY)
            ServiceHours(dailyType: "SATURDAY", busDirection: "UP", startTime: "2025-07-30T05:00", endTime: "2025-07-30T22:30", term: 15),
            ServiceHours(dailyType: "SATURDAY", busDirection: "DOWN", startTime: "2025-07-30T05:30", endTime: "2025-07-30T23:00", term: 15),

            // 공휴일 (HOLIDAY)
            ServiceHours(dailyType: "HOLIDAY", busDirection: "UP", startTime: "2025-07-30T05:30", endTime: "2025-07-30T22:00", term: 20),
            ServiceHours(dailyType: "HOLIDAY", busDirection: "DOWN", startTime: "2025-07-30T06:00", endTime: "2025-07-30T22:30", term: 20)
        ]
        setupOperationTime(mockServiceHours)
    }
    
    private func setupUI() {
        view.backgroundColor = AtchaColor.gray950
        
        operationStationTitleLabel.attributedText = AtchaFont.B3_M_15("운행지역", color: AtchaColor.white)
        stationImageView.image = UIImage.arrowTwoway
        stationImageView.contentMode = .scaleAspectFit
        startStationLabel.attributedText = AtchaFont.B6_R_14("출발지", color: AtchaColor.white)
        endStationLabel.attributedText = AtchaFont.B6_R_14("출발지", color: AtchaColor.white)
        
        stationStack.addArrangedSubview(startStationLabel)
        stationStack.addArrangedSubview(stationImageView)
        stationStack.addArrangedSubview(endStationLabel)
        stationStack.axis = .horizontal
        stationStack.spacing = 6
        
        operationRegionLabel.attributedText = AtchaFont.B7_M_13("서울", color: AtchaColor.gray200)
        
        operationTimeTitleLabel.attributedText = AtchaFont.B3_M_15("운행시간", color: AtchaColor.white)
        
        view.addSubViews(
            topNavigationBar,
            operationStationTitleLabel,
            stationStack,
            operationRegionLabel,
            operationTimeTitleLabel,
            operationTimeStack
        )
    }
    
    private func setupAutoLayout() {
        
        topNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.trailing.leading.equalToSuperview()
        }
        
        operationStationTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(topNavigationBar.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(16)
        }
        
        stationStack.snp.makeConstraints { make in
            make.top.equalTo(operationStationTitleLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(16)
        }
        
        operationRegionLabel.snp.makeConstraints { make in
            make.top.equalTo(stationStack.snp.bottom).offset(1)
            make.leading.equalToSuperview().offset(16)
        }
        
        operationTimeTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(operationRegionLabel.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(16)
        }
        
        operationTimeStack.snp.makeConstraints { make in
            make.top.equalTo(operationTimeTitleLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(16)
        }
    }
    
    // MARK: - 운행시간 세팅
    private func setupOperationTime(_ serviceHours: [ServiceHours]) {
        operationTimeStack.arrangedSubviews.forEach { $0.removeFromSuperview() } // 초기화
        
        // 요일별 그룹핑
        let grouped = Dictionary(grouping: serviceHours, by: { $0.dailyType })
        
        for dailyType in ["WEEKDAY", "SATURDAY", "HOLIDAY"] {
            guard let hours = grouped[dailyType] else { continue }
            
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 6
            
            // 요일 라벨
            let dayLabel = UILabel()
            dayLabel.attributedText = AtchaFont.B6_R_14(dailyType.DaytoKorean(), color: AtchaColor.gray200)
            rowStack.addArrangedSubview(dayLabel)
            
            dayLabel.snp.makeConstraints { make in
                make.width.equalTo(37)
            }
            
            if let up = hours.first(where: { $0.busDirection == "UP" }) {
                var text = "기점 \(up.startTime?.convertedToHourMinute ?? "")~\(up.endTime?.convertedToHourMinute ?? "")"
                
                if let down = hours.first(where: { $0.busDirection == "DOWN" }) {
                    // down이 있으면 그냥 이어붙이기
                    text += " / 종점 \(down.startTime?.convertedToHourMinute ?? "")~\(down.endTime?.convertedToHourMinute ?? "")"
                }
                
                let combinedLabel = UILabel()
                combinedLabel.attributedText = AtchaFont.B6_R_14(text, color: AtchaColor.white)
                rowStack.addArrangedSubview(combinedLabel)
            } else if let down = hours.first(where: { $0.busDirection == "DOWN" }) {
                // UP이 없고 DOWN만 있는 경우
                let downLabel = UILabel()
                downLabel.attributedText = AtchaFont.B6_R_14("종점 \(down.startTime?.convertedToHourMinute ?? "")~\(down.endTime?.convertedToHourMinute ?? "")", color: AtchaColor.white)
                rowStack.addArrangedSubview(downLabel)
            }
            
            operationTimeStack.addArrangedSubview(rowStack)
        }
    }
}
