//
//  BusDetailCell.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/31/25.
//

import UIKit
import SnapKit

enum BusCongestion: String, Codable {
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
    
    private let routeLineView: RouteLineView = RouteLineView(
        heightType: .short,
        circleType: .circle,
        lineColor: .regular,
        lineOpacity: .none
    )
    
    private let realTimeBusImageView: UIImageView = UIImageView()
    private let realTimeBusStack: UIStackView = UIStackView()
    private let remainSeatLabel: PaddingLabel = {
        let label = PaddingLabel(top: 3, left: 4, bottom: 3, right: 2) // 패딩을 가진 커스텀 UILabel
        label.backgroundColor = AtchaColor.Etc.paddingLabel
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()
    
    private var currentBusProgress: Double? = nil
    private var busYConstraint: Constraint?
    
    private let routeStack: UIStackView = UIStackView()
    
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
    
    // MARK: - 버스 노선 UI 업데이트
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let progress = currentBusProgress else { return }
        
        let baseHeight: CGFloat = isCurrentStationFlag ? 108 : 68
        let yPosition = baseHeight * CGFloat(progress)
        busYConstraint?.update(offset: yPosition + 12)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 버스 노선 UI
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
        
        routeStack.addArrangedSubview(routeLineView)
        routeStack.addArrangedSubview(busInfoStack)
        routeStack.axis = .horizontal
        routeStack.spacing = 15
        routeStack.alignment = .center
        
        realTimeBusImageView.image = UIImage.busDefualt20Px
        realTimeBusImageView.contentMode = .scaleAspectFit
        
        realTimeBusStack.axis = .horizontal
        realTimeBusStack.spacing = 5
        realTimeBusStack.addArrangedSubview(remainSeatLabel)
        realTimeBusStack.addArrangedSubview(realTimeBusImageView)
        
        contentView.addSubview(routeStack)
        contentView.addSubview(realTimeBusStack)
        
        layer.zPosition = 10
        contentView.clipsToBounds = false
        routeStack.clipsToBounds = false
        realTimeBusStack.clipsToBounds = false
        routeStack.layer.zPosition = 0
        realTimeBusStack.layer.zPosition = 100
    }
    
    // MARK: - 버스 노선 AutoLayout
    private func setupAutoLayout() {
        routeStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(76)
        }
        
        realTimeBusStack.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.trailing.equalTo(routeLineView.snp.trailing).offset(10)
            self.busYConstraint = make.top.equalTo(routeLineView.snp.top).offset(0).constraint
        }
        routeStack.layer.zPosition = 0
        realTimeBusStack.layer.zPosition = 10
    }
    
    func configure(
        with station: BusRouteStationList,
        isTurnPoint: Bool,
        isCurrentStation: Bool,
        busType: BusType,
        remainInfo: [RealTimeBusArrival],
        bus: [BusPositions],
        isAfterTurnPoint: Bool,
        isFirstStation: Bool,
        isLastStation: Bool
    ) {
        
        stationLabel.attributedText = AtchaFont.B6_R_14(lineHeight: 0, station.busStationName ?? "", color: AtchaColor.white)
        stationNumberLabel.attributedText = AtchaFont.B7_M_13(lineHeight: 0, station.busStationNumber ?? "", color: AtchaColor.gray200)
        
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
                
                let congestion = info.busCongestion
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
                        
                        if updated > 120 {
                            let congestionText = congestion?.displayText
                            let remainText: String
                            if let congestionText, !congestionText.isEmpty {
                                remainText = "\(remainStation)번째 전, \(congestionText)"
                            } else {
                                remainText = "\(remainStation)번째 전"
                            }
                            
                            label.attributedText = AtchaFont.B7_M_13(
                                lineHeight: 0,
                                "\(updated.toHourMinuteSecondString) (\(remainText))",
                                color: AtchaColor.Etc.remainTime
                            )
                        } else if updated > 0 { // 2분 이하 → "곧 도착"
                            let congestionText = congestion?.displayText
                            let remainText: String
                            if let congestionText, !congestionText.isEmpty {
                                remainText = "\(remainStation)번째 전, \(congestionText)"
                            } else {
                                remainText = "\(remainStation)번째 전"
                            }
                            
                            label.attributedText = AtchaFont.B7_M_13(
                                lineHeight: 0,
                                "곧 도착 (\(remainText))",
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
            realTimeBusImageView.image = UIImage.busMainline20Px
            configureRouteLine(
                isCurrentStation: isCurrentStation,
                isTurnPoint: isTurnPoint,
                isAfterTurnPoint: isAfterTurnPoint,
                isFirstStation: isFirstStation,
                isLastStation: isLastStation,
                color: .mainline
            )
        case .일반: // general
            realTimeBusImageView.image = UIImage.busGeneral20Px
            configureRouteLine(
                isCurrentStation: isCurrentStation,
                isTurnPoint: isTurnPoint,
                isAfterTurnPoint: isAfterTurnPoint,
                isFirstStation: isFirstStation,
                isLastStation: isLastStation,
                color: .general
            )
        case .외곽, .지선: // regular
            realTimeBusImageView.image = UIImage.busRegular20Px
            configureRouteLine(
                isCurrentStation: isCurrentStation,
                isTurnPoint: isTurnPoint,
                isAfterTurnPoint: isAfterTurnPoint,
                isFirstStation: isFirstStation,
                isLastStation: isLastStation,
                color: .regular
            )
        case .마을, .순환, .농어촌: // town
            realTimeBusImageView.image = UIImage.busTown20Px
            configureRouteLine(
                isCurrentStation: isCurrentStation,
                isTurnPoint: isTurnPoint,
                isAfterTurnPoint: isAfterTurnPoint,
                isFirstStation: isFirstStation,
                isLastStation: isLastStation,
                color: .town
            )
        case .직행좌석, .간선급행, .광역, .급행, .시외, .시외버스, .고속버스: // widearea
            realTimeBusImageView.image = UIImage.busWidearea20Px
            configureRouteLine(
                isCurrentStation: isCurrentStation,
                isTurnPoint: isTurnPoint,
                isAfterTurnPoint: isAfterTurnPoint,
                isFirstStation: isFirstStation,
                isLastStation: isLastStation,
                color: .widearea
            )
        case .공항, .리무진: // airport
            realTimeBusImageView.image = UIImage.busAirport20Px
            configureRouteLine(
                isCurrentStation: isCurrentStation,
                isTurnPoint: isTurnPoint,
                isAfterTurnPoint: isAfterTurnPoint,
                isFirstStation: isFirstStation,
                isLastStation: isLastStation,
                color: .airport
            )
        case .unknown: // default
            realTimeBusImageView.image = UIImage.busDefualt20Px
            configureRouteLine(
                isCurrentStation: isCurrentStation,
                isTurnPoint: isTurnPoint,
                isAfterTurnPoint: isAfterTurnPoint,
                isFirstStation: isFirstStation,
                isLastStation: isLastStation,
                color: .gray200
            )
        }
        
        // 실시간 버스 위치 잡기
        if let matchedBus = bus.first(where: { $0.sectionOrder == station.order }),
           let progress = matchedBus.sectionProgress {
            self.currentBusProgress = progress // 0 ~ 1 값 저장
            realTimeBusStack.isHidden = false
            realTimeBusStack.layer.zPosition = 100
            contentView.bringSubviewToFront(realTimeBusStack)
            let combined = NSMutableAttributedString()
            
            if let vehicleNumber = matchedBus.vehicleNumber {
                let vehicleNumberAttr = AtchaFont.M_11(
                    lineHeight: 0,
                    "\(vehicleNumber) ",
                    color: AtchaColor.gray200
                )
                combined.append(vehicleNumberAttr)
            }
            
            if busType == .광역, let remainSeats = matchedBus.remainSeats {
                let remainAttr = AtchaFont.M_11(
                    lineHeight: 0,
                    "\(remainSeats)석",
                    color: AtchaColor.Bus.widearea
                )
                combined.append(remainAttr)
            } else if let congestionRaw = matchedBus.busCongestion,
                      let congestion = BusCongestion(rawValue: congestionRaw),
                      let text = congestion.displayText {
                
                let color: UIColor
                switch congestion {
                case .low: color = AtchaColor.Bus.regular
                case .medium: color = AtchaColor.Bus.mainline
                case .high, .veryHigh: color = AtchaColor.Bus.widearea
                case .unknown: color = AtchaColor.gray200
                }
                
                let congestionAttr = AtchaFont.M_11(
                    lineHeight: 0,
                    "\(text) ",
                    color: color
                )
                combined.append(congestionAttr)
            }
            
            remainSeatLabel.attributedText = combined
            
        } else {
            self.currentBusProgress = nil
            realTimeBusStack.isHidden = true
        }
    }
    
    // MARK: - 버스 노선 Configuration
    private func configureRouteLine(
        isCurrentStation: Bool,
        isTurnPoint: Bool,
        isAfterTurnPoint: Bool,
        isFirstStation: Bool,
        isLastStation: Bool,
        color: UIColor
    ) {
        let circle: RouteCircleType = isTurnPoint ? .rotation : .circle
        let height: RouteHeightType = isCurrentStation ? .long : .short
        
        if isCurrentStation {
            if isTurnPoint {
                // 4. 현재 정류장이면서 회차 정류장(회차 정류장은 무조건 가운데 정류장)
                routeLineView.configure(
                    heightType: height,
                    circleType: circle,
                    lineColor: color,
                    lineOpacity: .bottom(0.3),
                    linePosition: .both
                )
            } else if isAfterTurnPoint {
                if isLastStation {
                    // 5. 현재 정류장이면서 회차 이후 정류장이면서 마지막 정류장
                    routeLineView.configure(
                        heightType: height,
                        circleType: circle,
                        lineColor: color,
                        lineOpacity: .all(0.3),
                        linePosition: .topOnly
                    )
                } else {
                    // 6. 현재 정류장이면서 회차 이후 정류장이면서 가운데 정류장
                    routeLineView.configure(
                        heightType: height,
                        circleType: circle,
                        lineColor: color,
                        lineOpacity: .all(0.3),
                        linePosition: .both
                    )
                }
            } else {
                if isFirstStation {
                    // 1. 현재 정류장이면서 회차아니면서 첫번째 정류장
                    routeLineView.configure(
                        heightType: height,
                        circleType: circle,
                        lineColor: color,
                        lineOpacity: .none,
                        linePosition: .bottomOnly
                    )
                } else if isLastStation {
                    // 2. 현재 정류장이면서 회차아니면서 마지막 정류장
                    routeLineView.configure(
                        heightType: height,
                        circleType: circle,
                        lineColor: color,
                        lineOpacity: .none,
                        linePosition: .topOnly
                    )
                } else {
                    // 3. 현재 정류장이면서 회차아니면서 가운데 정류장
                    routeLineView.configure(
                        heightType: height,
                        circleType: circle,
                        lineColor: color,
                        lineOpacity: .none,
                        linePosition: .both
                    )
                }
            }
        } else {
            if isTurnPoint {
                // 10. 현재 정류장이 아니면서 회차 정류장
                routeLineView.configure(
                    heightType: height,
                    circleType: circle,
                    lineColor: color,
                    lineOpacity: .bottom(0.3),
                    linePosition: .both
                )
            } else if isAfterTurnPoint {
                if isLastStation {
                    // 11. 현재 정류장이 아니면서 회차 이후 정류장이면서 마지막 정류장
                    routeLineView.configure(
                        heightType: height,
                        circleType: circle,
                        lineColor: color,
                        lineOpacity: .all(0.3),
                        linePosition: .topOnly
                    )
                } else {
                    // 12. 현재 정류장이 아니면서 회차 이후 정류장이면서 가운데 정류장
                    routeLineView.configure(
                        heightType: height,
                        circleType: circle,
                        lineColor: color,
                        lineOpacity: .all(0.3),
                        linePosition: .both
                    )
                }
            } else {
                if isFirstStation {
                    // 7. 현재 정류장이 아니면서 회차 아니면서 첫번째 정류장
                    routeLineView.configure(
                        heightType: height,
                        circleType: circle,
                        lineColor: color,
                        lineOpacity: .none,
                        linePosition: .bottomOnly
                    )
                } else if isLastStation {
                    // 8. 현재 정류장이 아니면서 회차 아니면서 마지막 정류장
                    routeLineView.configure(
                        heightType: height,
                        circleType: circle,
                        lineColor: color,
                        lineOpacity: .none,
                        linePosition: .topOnly
                    )
                } else {
                    // 9. 현재 정류장이 아니면서 회차 아니면서 가운데 정류장
                    routeLineView.configure(
                        heightType: height,
                        circleType: circle,
                        lineColor: color,
                        lineOpacity: .none,
                        linePosition: .both
                    )
                }
            }
        }
    }
    
    func ensureBusOnTop() {
        guard contentView.subviews.contains(realTimeBusStack) else { return }
        routeStack.layer.zPosition = 0
        realTimeBusStack.layer.zPosition = 100
        layer.zPosition = 10
        contentView.bringSubviewToFront(realTimeBusStack)
    }
}

//extension BusRouteCell{
//    static func busRouteLayout() -> NSCollectionLayoutSection {
//        
//        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(68))
//        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        
//        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(68))
//        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
//        
//        let section = NSCollectionLayoutSection(group: group)
//        
//        return section
//    }
//}
