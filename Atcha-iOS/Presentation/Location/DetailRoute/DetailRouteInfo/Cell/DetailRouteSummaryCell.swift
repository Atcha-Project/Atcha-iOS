//
//  DetailRouteSummaryCell.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 9/14/25.
//

import UIKit

final class DetailRouteSummaryCell: UICollectionViewCell {
    static let id: String = "DetailRouteSummaryCell"
    private let totalTimeLabel: UILabel = UILabel()
    private let startEndTimeLabel: UILabel = UILabel()
    private let progressView: DetailRouteProgressView = DetailRouteProgressView()
    private let dividerView: UIView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubViews(totalTimeLabel,
                    startEndTimeLabel,
                    progressView,
                    dividerView)
        dividerView.backgroundColor = .opacity100
    }
    
    private func setupAutoLayout() {
        totalTimeLabel.snp.makeConstraints { make in
            make.height.equalTo(34)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(12)
        }
        
        startEndTimeLabel.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.top.equalTo(totalTimeLabel.snp.bottom).offset(6)
        }
        
        progressView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(16)
            make.top.equalTo(startEndTimeLabel.snp.bottom).offset(16)
        }
        
        dividerView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(progressView.snp.bottom).offset(24)
        }
    }
    
    func configure(infos: [LegTrafficInfo]) {
        totalTimeLabel.attributedText = AtchaFont.H1_B_26(infos.first?.totalTime ?? "")
        startEndTimeLabel.attributedText = AtchaFont.B7_M_13(infos.first?.timeText ?? "", color: .gray400)
        progressView.configure(infos: infos)
    }
}
