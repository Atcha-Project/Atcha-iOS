//
//  DetailRouteSummaryView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 9/14/25.
//

import UIKit
import SnapKit

final class DetailRouteSummaryView: UIView {
    private let summaryLabel = UILabel()
    private let arrowImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupLayout()
    }
    
    private func setupUI() {
        summaryLabel.font = .systemFont(ofSize: 14, weight: .regular)
        summaryLabel.textColor = .white
        
        arrowImageView.image = UIImage(systemName: "chevron.down")
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.tintColor = .gray200
        
        addSubview(summaryLabel)
        addSubview(arrowImageView)
    }
    
    private func setupLayout() {
        summaryLabel.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalTo(summaryLabel)
            make.leading.equalTo(summaryLabel.snp.trailing).offset(4)
            make.trailing.equalToSuperview()
            make.width.height.equalTo(10)
        }
    }
    
    func configure(duration: String, stops: Int) {
        summaryLabel.attributedText = AtchaFont.B7_M_13("\(duration), \(stops)개 정류장 이동", color: .white)
    }
}
