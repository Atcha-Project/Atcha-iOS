//
//  DetailRouteEndCell.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 8/1/25.
//

import UIKit
import SnapKit

final class DetailRouteEndCell: UICollectionViewCell {
    static let id: String = "DetailRouteEndCell"
    
    private let imageView: UIImageView = UIImageView()
    private let locationLabel: UILabel = UILabel()
    private let timeBadegLabel: TimeBadgeLabel = TimeBadgeLabel()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [timeBadegLabel, imageView, locationLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 5
        return stack
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
        
        contentView.backgroundColor = .green.withAlphaComponent(0.3)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        imageView.image = UIImage.smallEndMarker
        imageView.contentMode = .scaleAspectFit
        addSubViews(stackView)
    }
    
    func setupAutoLayout() {
        imageView.snp.makeConstraints { make in
            make.size.equalTo(36)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }
    }
    
    func configure(info: LegTrafficInfo?) {
        timeBadegLabel.setText(info?.timeText)
        locationLabel.attributedText = AtchaFont.B3_M_15("우리집")
    }
}
