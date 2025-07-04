//
//  TabCell.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/3/25.
//

import Foundation
import UIKit

class CourseTabCell: UICollectionViewCell {
    private let titleLabel: UILabel = UILabel()
    private let indicatorView: UIView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Course Tab UI
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(indicatorView)
        
        indicatorView.backgroundColor = .white
        indicatorView.isHidden = true
        indicatorView.layer.cornerRadius = 1
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        indicatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.leading.trailing.equalToSuperview()
        }
    }
    
    // MARK: - Course Tab Configure
    func configure(title: String, selected: Bool) {
        titleLabel.attributedText = selected ? AtchaFont.B5_SB_14(title, color: AtchaColor.white) : AtchaFont.B6_R_14(title, color: AtchaColor.gray400)
        indicatorView.isHidden = !selected
    }
}
