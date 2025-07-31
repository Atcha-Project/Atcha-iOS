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
        contentView.backgroundColor = .blue
//        contentView.backgroundColor = .gray950
    }
    
    func setupAutoLayout() {
        imageView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        locationLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).inset(15)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(info: LegTrafficInfo) {
        print("default Info : \(info)")
        imageView.image = UIImage.markerStart
        locationLabel.attributedText = AtchaFont.B3_M_15("앗차 강남점")
    }
}
