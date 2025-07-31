//
//  DetailRouteSubwayCell.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/31/25.
//

import UIKit
import SnapKit

final class DetailRouteSubwayCell: UICollectionViewCell {
    static let id: String = "DetailRouteSubwayCell"
    
    private let lineStackView: UIStackView = UIStackView()
    private let iconImageView: UIImageView = UIImageView()
    private let stickView: UIView = UIView()
    private let circleView: UIView = UIView()
    
    private let startStackView: UIStackView = UIStackView()
    private let startStationLabel: UILabel = UILabel()
    private let startLabel: UILabel = UILabel()
    
    private let summaryLabel: UILabel = UILabel()
    
    private let busStationStackView: UIStackView = UIStackView()
    
    private let endStackView: UIStackView = UIStackView()
    private let endStationLabel: UILabel = UILabel()
    private let endLabel: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
        
        contentView.backgroundColor = .cyan
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
    }
    
    private func setupGesture() {
        
    }
    func configure(info: LegTrafficInfo) {
        print("subway Info : \(info)")
    }
}
