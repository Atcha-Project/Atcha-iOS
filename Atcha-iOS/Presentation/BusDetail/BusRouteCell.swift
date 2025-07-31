//
//  BusDetailCell.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/31/25.
//

import UIKit
import SnapKit

class BusRouteCell: UICollectionViewCell {
    static let reusableId: String = "BusRouteCell"
    
    private let stationLabel: UILabel = UILabel()
    private let stationNumberLabel: UILabel = UILabel()
    private let stationStack: UIStackView = UIStackView()
    
    private let remainTimeLabel: UILabel = UILabel()
    private let busInfoStack: UIStackView = UIStackView()
    
    private let routeLineImageView: UIImageView = UIImageView()
    private let routeStack: UIStackView = UIStackView()
    private var leadingConstraint: Constraint?
    private var lineHeightConstraint: Constraint?
    private var lineWidthConstraint: Constraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
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
        busInfoStack.addArrangedSubview(remainTimeLabel)
        busInfoStack.axis = .vertical
        busInfoStack.spacing = 5
        busInfoStack.alignment = .leading
        
        routeLineImageView.contentMode = .scaleAspectFill
        routeStack.addArrangedSubview(routeLineImageView)
        routeStack.addArrangedSubview(busInfoStack)
        routeStack.axis = .horizontal
        routeStack.spacing = 10
        routeStack.alignment = .center
        
        contentView.addSubview(routeStack)
    }
    
    private func setupAutoLayout() {
        routeStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            self.leadingConstraint = make.leading.equalToSuperview().offset(76).constraint
        }
        
        routeLineImageView.snp.makeConstraints { make in
            self.lineWidthConstraint = make.width.equalTo(14).constraint
            self.lineHeightConstraint = make.height.equalTo(68).constraint
        }
    }
    
    func configure(
        with station: BusRouteStationList,
        isTurnPoint: Bool,
        isCurrentStation: Bool,
        busType: BusType,
        buses: [BusPositions],
        isAfterTurnPoint: Bool
    ) {
        stationLabel.attributedText = AtchaFont.B6_R_14(lineHeight: 0, station.busStationName ?? "", color: AtchaColor.white)
        stationNumberLabel.attributedText = AtchaFont.B7_M_13(lineHeight: 0, station.busStationNumber ?? "", color: AtchaColor.gray200)
        
        leadingConstraint?.update(offset: isTurnPoint ? 52 : 76)
        lineHeightConstraint?.update(offset: isCurrentStation ? 107 : 68)
        lineWidthConstraint?.update(offset: isTurnPoint ? 38 : 14)

        switch busType {
        case .일반, .외곽, .지선: // regular
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
        case .마을, .순환, .농어촌: // town
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
        case .직행좌석, .간선급행, .광역, .급행, .시외, .시외버스, .고속버스: // widearea
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
        case .공항, .리무진: // airport
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
        case .unknown: // defualt
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
        }
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
}
