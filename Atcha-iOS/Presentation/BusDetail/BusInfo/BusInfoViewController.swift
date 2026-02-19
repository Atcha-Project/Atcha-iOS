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
            [weak self] in
            self?.navigationController?.popViewController(animated: true)
        } onClose: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
            self?.navigationController?.popViewController(animated: true)
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
    
    private let dispatchTitleLabel: UILabel = UILabel()
    private let dispatchStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 15
        return stack
    }()
    
    private let bottomNoticeStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        return stack
    }()
    private let bottomNoticeImageView: UIImageView = UIImageView()
    private let bottomNoticeLabel: UILabel = UILabel()
    
    private let noSearchStack: UIStackView = UIStackView()
    private let noSearchImageView: UIImageView = UIImageView()
    private let noSearchLabel: UILabel = UILabel()
    
    private let refreshButton: RefreshView = RefreshView(background: .default)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupNoSearchUI()
        setupAutoLayout()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AmplitudeManager.shared.trackScreen(.bus_info)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        refreshButton.stop()
    }
    
    // MARK: ViewModel 바인딩
    private func bind() {
        viewModel.$operationInfo
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] info in
                guard let self else { return }
                
                let hours = info?.serviceHours ?? []
                setupOperationTime(hours)
                setupDispatchTime(hours)
                
                startStationLabel.attributedText = AtchaFont.B6_R_14(info?.startStationName ?? "출발지", color: AtchaColor.white)
                endStationLabel.attributedText = AtchaFont.B6_R_14(info?.endStationName ?? "도착지", color: AtchaColor.white)
                self.setErrorUI(false)
            }
            .store(in: &cancellables)
        
        viewModel.$isServerError
                .removeDuplicates()
                .receive(on: RunLoop.main)
                .sink { [weak self] isError in
                    self?.setErrorUI(isError)
                }
                .store(in: &cancellables)
    }
    
    // MARK: 버스 운영 정보 UI
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
        
        operationRegionLabel.attributedText = AtchaFont.B7_M_13(viewModel.busRouteInfo.serviceRegion?.serviceRegionToKorean() ?? "서울", color: AtchaColor.gray200)
        operationTimeTitleLabel.attributedText = AtchaFont.B3_M_15("운행시간", color: AtchaColor.white)
        dispatchTitleLabel.attributedText = AtchaFont.B3_M_15("배차간격", color: AtchaColor.white)
        
        bottomNoticeImageView.image = UIImage.infoOutlined
        bottomNoticeImageView.contentMode = .scaleAspectFit
        bottomNoticeImageView.tintColor = AtchaColor.gray200
        bottomNoticeLabel.attributedText = AtchaFont.R_12("운행상황 및 운수사의 정책에 따라 실제와 다를 수 있습니다.", color: AtchaColor.gray200)
        bottomNoticeStack.addArrangedSubview(bottomNoticeImageView)
        bottomNoticeStack.addArrangedSubview(bottomNoticeLabel)
        
        refreshButton.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onRefreshTapped))
        refreshButton.addGestureRecognizer(tap)
        
        view.addSubViews(
            topNavigationBar,
            operationStationTitleLabel,
            stationStack,
            operationRegionLabel,
            operationTimeTitleLabel,
            operationTimeStack,
            dispatchTitleLabel,
            dispatchStack,
            bottomNoticeStack,
            refreshButton
        )
    }
    
    // MARK: 버스 운영 정보 AutoLayout
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
        
        dispatchTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(operationTimeStack.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(16)
        }
        
        dispatchStack.snp.makeConstraints { make in
            make.top.equalTo(dispatchTitleLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(16)
        }
        
        bottomNoticeImageView.snp.makeConstraints { make in
            make.size.equalTo(12)
        }
        
        bottomNoticeStack.snp.makeConstraints { make in
            make.top.equalTo(dispatchStack.snp.bottom).offset(26)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(14)
        }
        
        refreshButton.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
        }
    }
    
    // MARK: - 검색 결과 없을 경우 UI
    private func setupNoSearchUI() {
        noSearchImageView.image = UIImage.atchaGray
        noSearchImageView.contentMode = .scaleAspectFit
        noSearchLabel.attributedText = AtchaFont.B4_R_15("버스 정보를 불러오지 못 했어요\n새로고침 해주세요", color: AtchaColor.gray400, alignment: .center)
        noSearchLabel.numberOfLines = 0
        
        noSearchStack.addArrangedSubview(noSearchImageView)
        noSearchStack.addArrangedSubview(noSearchLabel)
        noSearchStack.axis = .vertical
        noSearchStack.spacing = 16
        noSearchStack.alignment = .center
        
        view.addSubview(noSearchStack)
        noSearchStack.isHidden = true
        
        noSearchStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(90)
        }
    }
    
    private func setErrorUI(_ isError: Bool) {
        refreshButton.stop()
        noSearchStack.isHidden = !isError

        // 기존 컨텐츠 숨김/표시
        operationStationTitleLabel.isHidden = isError
        stationStack.isHidden = isError
        operationRegionLabel.isHidden = isError
        operationTimeTitleLabel.isHidden = isError
        operationTimeStack.isHidden = isError
        dispatchTitleLabel.isHidden = isError
        dispatchStack.isHidden = isError
        bottomNoticeStack.isHidden = isError
    }
    
    // MARK: - 버스 운행시간 세팅
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
            dayLabel.attributedText = AtchaFont.B6_R_14(dailyType.dayToKorean(), color: AtchaColor.gray200)
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
    
    // MARK: - 버스 운행 간격 세팅
    private func setupDispatchTime(_ serviceHours: [ServiceHours]) {
        dispatchStack.arrangedSubviews.forEach { $0.removeFromSuperview() } // 초기화
        let grouped = Dictionary(grouping: serviceHours, by: { $0.dailyType })
        
        for dailyType in ["WEEKDAY", "SATURDAY", "HOLIDAY"] {
            guard let hours = grouped[dailyType] else { continue }
            
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 6
            
            // 요일 라벨
            let dayLabel = UILabel()
            dayLabel.attributedText = AtchaFont.B6_R_14(dailyType.dayToKorean(), color: AtchaColor.gray200)
            rowStack.addArrangedSubview(dayLabel)
            
            // term 값 가져오기 (보통 UP/DOWN이 같다고 가정)
            if let up = hours.first(where: { $0.busDirection == "UP" }),
               let term = up.term {
                let termLabel = UILabel()
                termLabel.attributedText = AtchaFont.B6_R_14("\(term)분", color: AtchaColor.white)
                rowStack.addArrangedSubview(termLabel)
            } else if let down = hours.first(where: { $0.busDirection == "DOWN" }),
                      let term = down.term {
                // UP이 없을 경우 DOWN 기준
                let termLabel = UILabel()
                termLabel.attributedText = AtchaFont.B6_R_14("\(term)분", color: AtchaColor.white)
                rowStack.addArrangedSubview(termLabel)
            }
            
            dispatchStack.addArrangedSubview(rowStack)
        }
    }
    
    @objc private func onRefreshTapped() {
        refreshButton.start()
        showLoadingOnce()
        viewModel.refresh()
    }
}
