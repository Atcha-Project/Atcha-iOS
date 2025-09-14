//
//  DetailRouteStartCell.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/31/25.
//

import UIKit
import SnapKit

final class DetailRouteStartCell: UICollectionViewCell {
    static let id: String = "DetailRouteStartCell"
    
    private let imageView: UIImageView = UIImageView()
    private let locationLabel: UILabel = UILabel()
    
    private let timeLabel: UILabel = UILabel()
    private let timeBackView: UIView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        imageView.contentMode = .scaleAspectFit
        addSubViews(imageView, locationLabel)
    }
    
    func setupAutoLayout() {
        imageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(6)
            make.centerY.equalToSuperview()
            make.top.equalToSuperview().offset(22)
            make.size.equalTo(36)
        }
        
        locationLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(15)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(address: String, info: LegTrafficInfo?) {
        imageView.image = UIImage.smallStartMarker
        locationLabel.attributedText = AtchaFont.B3_M_15(address)
    }
}
