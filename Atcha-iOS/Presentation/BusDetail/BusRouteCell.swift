//
//  BusDetailCell.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/31/25.
//

import UIKit
import SnapKit

enum BusCongestion: String {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case veryHigh = "VERY_HIGH"
    case unknown = "UNKNOWN"
    
    var displayText: String? {
        switch self {
        case .low: return "여유"
        case .medium: return "보통"
        case .high, .veryHigh: return "혼잡"
        case .unknown: return nil
        }
    }
}

class BusRouteCell: UICollectionViewCell {
    static let reusableId: String = "BusRouteCell"
    private var countdownTimers: [Timer] = []
    private var remainSeconds: [Int] = []
    private let stationLabel: UILabel = UILabel()
    private let stationNumberLabel: UILabel = UILabel()
    private let stationStack: UIStackView = UIStackView()
    private var isCurrentStationFlag: Bool = false
    
    private let remainTimeStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 3
        stack.alignment = .leading
        return stack
    }()
    private let busInfoStack: UIStackView = UIStackView()
    
    private let routeLineImageView: UIImageView = UIImageView()
    private let realTimeBusImageView: UIImageView = UIImageView()
    private var currentBusProgress: Double? = nil
    private var busYConstraint: Constraint?
    
    private let routeStack: UIStackView = UIStackView()
    private var leadingConstraint: Constraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 타이머 초기화
        countdownTimers.forEach { $0.invalidate() }
        countdownTimers.removeAll()
        remainSeconds.removeAll()
        remainTimeStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let progress = currentBusProgress else { return }
        
        let baseHeight: CGFloat = isCurrentStationFlag ? 107 : 68
        let yPosition = baseHeight * CGFloat(progress)
        busYConstraint?.update(offset: yPosition + 10)
        contentView.bringSubviewToFront(realTimeBusImageView)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        stationStack.addArrangedSubview(stationLabel)
        stationStack.addArrangedSubview(stationNumberLabel)
        stationStack.axis = .vertical
        stationStack.spacing = 1
        stationStack.alignment = .leading
        
        busInfoStack.addArrangedSubview(stationStack)
        busInfoStack.addArrangedSubview(remainTimeStack)
        busInfoStack.axis = .vertical
        busInfoStack.spacing = 5
        busInfoStack.alignment = .leading
        
        routeLineImageView.contentMode = .scaleAspectFill
        routeStack.addArrangedSubview(routeLineImageView)
        routeStack.addArrangedSubview(busInfoStack)
        routeStack.axis = .horizontal
        routeStack.spacing = 10
        routeStack.alignment = .center
        
        realTimeBusImageView.image = UIImage.airportBus
        realTimeBusImageView.contentMode = .scaleAspectFit
        
        contentView.addSubview(routeStack)
        contentView.addSubview(realTimeBusImageView)
    }
    
    private func setupAutoLayout() {
        routeStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            self.leadingConstraint = make.leading.equalToSuperview().offset(76).constraint
        }
        
        realTimeBusImageView.snp.makeConstraints { make in
            make.size.equalTo(20)
            make.trailing.equalTo(routeLineImageView.snp.trailing).offset(3)
            self.busYConstraint = make.top.equalTo(routeLineImageView.snp.top).offset(0).constraint
        }
    }
    
    func configure(
        with station: BusRouteStationList,
        isTurnPoint: Bool,
        isCurrentStation: Bool,
        busType: BusType,
        remainInfo: [RealTimeBusArrival],
        bus: [BusPositions],
        isAfterTurnPoint: Bool
    ) {
        stationLabel.attributedText = AtchaFont.B6_R_14(lineHeight: 0, station.busStationName ?? "", color: AtchaColor.white)
        stationNumberLabel.attributedText = AtchaFont.B7_M_13(lineHeight: 0, station.busStationNumber ?? "", color: AtchaColor.gray200)
        
        leadingConstraint?.update(offset: isTurnPoint ? 52 : 76)
        
        remainTimeStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        countdownTimers.forEach { $0.invalidate() }
        countdownTimers.removeAll()
        remainSeconds.removeAll()
        self.isCurrentStationFlag = isCurrentStation
        
        if isCurrentStation {
            for info in remainInfo {
                guard let vehicleId = info.vehicleId else { continue }
                
                let matchedBus = bus.first(where: { $0.vehicleId == vehicleId })
                
                var remainStation = 0
                if let matchedBus = matchedBus,
                   let busSection = matchedBus.sectionOrder,
                   let currentOrder = station.order {
                    remainStation = currentOrder - busSection
                }
                
                let congestion = BusCongestion(rawValue: info.busCongestion ?? "")
                let seconds = info.remainingTime ?? 0
                remainSeconds.append(seconds)
                
                let label = UILabel()
                label.attributedText = AtchaFont.B7_M_13(
                    lineHeight: 0,
                    seconds.toHourMinuteSecondString, // 새 함수 (초 → "분 초" 변환)
                    color: AtchaColor.Etc.remainTime
                )
                remainTimeStack.addArrangedSubview(label)
                
                // 타이머 시작
                let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self, weak label] timer in
                    guard let self = self, let label = label else {
                        timer.invalidate()
                        return
                    }
                    
                    if let index = self.remainTimeStack.arrangedSubviews.firstIndex(of: label) {
                        self.remainSeconds[index] = max(0, self.remainSeconds[index] - 1)
                        let updated = self.remainSeconds[index]
                        
                        if updated > 180 { // 3분 초과 → 일반 시간 표시
                            label.attributedText = AtchaFont.B7_M_13(
                                lineHeight: 0,
                                "\(updated.toHourMinuteSecondString) (\(remainStation)번째 전, \(congestion?.displayText ?? ""))",
                                color: AtchaColor.Etc.remainTime
                            )
                        } else if updated > 0 { // 3분 이하 → "곧 도착"
                            label.attributedText = AtchaFont.B7_M_13(
                                lineHeight: 0,
                                "곧 도착 (\(remainStation)번째 전, \(congestion?.displayText ?? ""))",
                                color: AtchaColor.Etc.remainTime
                            )
                        } else {
                            // 시간이 0이 되면 스택에서 제거
                            self.remainTimeStack.removeArrangedSubview(label)
                            label.removeFromSuperview()
                            self.remainSeconds.remove(at: index)
                            timer.invalidate()
                        }
                    }
                }
                RunLoop.main.add(timer, forMode: .common)
                countdownTimers.append(timer)
            }
        }
        
        
        switch busType {
        case .좌석, .간선: // mainline
            if isCurrentStation {
                if isTurnPoint {
                    // 2. 현재 정류장이면서 회차 정류장 → mainline-long-turn
                    routeLineImageView.image = UIImage.mainlineLongTurn
                } else if isAfterTurnPoint {
                    // 3. 현재 정류장이면서 회차 이후 정류장 → mainline-long-opacity
                    routeLineImageView.image = UIImage.mainlineLongOpacity
                } else {
                    // 1. 현재 정류장이면서 회차 아님 → mainline-long
                    routeLineImageView.image = UIImage.mainlineLong
                }
            } else {
                if isTurnPoint {
                    // 5. 현재X, 회차 정류장 → mainline-short-turn
                    routeLineImageView.image = UIImage.mainlineShortTurn
                } else if isAfterTurnPoint {
                    // 6. 현재X, 회차 이후 → mainline-short-opacity
                    routeLineImageView.image = UIImage.mainlineShortOpacity
                } else {
                    // 4. 현재X, 회차 아님 → mainline-short
                    routeLineImageView.image = UIImage.mainlineShort
                }
            }
        case .일반, .외곽, .지선: // regular
            if isCurrentStation {
                if isTurnPoint {
                    routeLineImageView.image = UIImage.regularLongTurn
                } else if isAfterTurnPoint {
                    routeLineImageView.image = UIImage.regularLongOpacity
                } else {
                    routeLineImageView.image = UIImage.regularLong
                }
            } else {
                if isTurnPoint {
                    routeLineImageView.image = UIImage.regularShortTurn
                } else if isAfterTurnPoint {
                    routeLineImageView.image = UIImage.regularShortOpacity
                } else {
                    routeLineImageView.image = UIImage.regularShort
                }
            }
        case .마을, .순환, .농어촌: // town
            if isCurrentStation {
                if isTurnPoint {
                    routeLineImageView.image = UIImage.townLongTurn
                } else if isAfterTurnPoint {
                    routeLineImageView.image = UIImage.townLongOpacity
                } else {
                    routeLineImageView.image = UIImage.townLong
                }
            } else {
                if isTurnPoint {
                    routeLineImageView.image = UIImage.townShortTurn
                } else if isAfterTurnPoint {
                    routeLineImageView.image = UIImage.townShortOpacity
                } else {
                    routeLineImageView.image = UIImage.townShort
                }
            }
        case .직행좌석, .간선급행, .광역, .급행, .시외, .시외버스, .고속버스: // widearea
            if isCurrentStation {
                if isTurnPoint {
                    routeLineImageView.image = UIImage.wideareaLongTurn
                } else if isAfterTurnPoint {
                    routeLineImageView.image = UIImage.wideareaLongOpacity
                } else {
                    routeLineImageView.image = UIImage.wideareaLong
                }
            } else {
                if isTurnPoint {
                    routeLineImageView.image = UIImage.wideareaShortTurn
                } else if isAfterTurnPoint {
                    routeLineImageView.image = UIImage.wideareaShortOpacity
                } else {
                    routeLineImageView.image = UIImage.wideareaShort
                }
            }
        case .공항, .리무진: // airport
            if isCurrentStation {
                if isTurnPoint {
                    routeLineImageView.image = UIImage.airportLongTurn
                } else if isAfterTurnPoint {
                    routeLineImageView.image = UIImage.airportLongOpacity
                } else {
                    routeLineImageView.image = UIImage.airportLong
                }
            } else {
                if isTurnPoint {
                    routeLineImageView.image = UIImage.airportShortTurn
                } else if isAfterTurnPoint {
                    routeLineImageView.image = UIImage.airportShortOpacity
                } else {
                    routeLineImageView.image = UIImage.airportShort
                }
            }
        case .unknown: // default
            if isCurrentStation {
                if isTurnPoint {
                    routeLineImageView.image = UIImage.defaultLongTurn
                } else if isAfterTurnPoint {
                    routeLineImageView.image = UIImage.defaultLongOpacity
                } else {
                    routeLineImageView.image = UIImage.defaultLong
                }
            } else {
                if isTurnPoint {
                    routeLineImageView.image = UIImage.defaultShortTurn
                } else if isAfterTurnPoint {
                    routeLineImageView.image = UIImage.defaultShortOpacity
                } else {
                    routeLineImageView.image = UIImage.defaultShort
                }
            }
        }
        
        // 실시간 버스 위치 잡기
        if let matchedBus = bus.first(where: { $0.sectionOrder == station.order }),
           let progress = matchedBus.sectionProgress {
            self.currentBusProgress = progress // 0 ~ 1 값 저장
            realTimeBusImageView.isHidden = false
        } else {
            self.currentBusProgress = nil
            realTimeBusImageView.isHidden = true
        }
        
        setNeedsLayout()
    }
}

extension BusRouteCell{
    static func busRouteLayout() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(68))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(68))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        return section
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if currentBusProgress != nil {
            self.layer.zPosition = 10
        } else {
            self.layer.zPosition = 0
        }
    }
}
