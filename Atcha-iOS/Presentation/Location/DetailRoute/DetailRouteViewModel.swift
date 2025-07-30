//
//  DetailRouteViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import Foundation
import UIKit

final class DetailRouteViewModel: BaseViewModel {
    private let infos: LegInfo
    @Published var legtPathInfo: [LegPathInfo] = []
    @Published var legTrafficInfo: [LegTrafficInfo] = []
    
    init(infos: LegInfo) {
        self.infos = infos
        
        super.init()
        self.bind()
    }
    
    private func bind() {
        self.legtPathInfo = infos.pathInfo
        self.legTrafficInfo = infos.trafficInfo
        
        // 시간
        let time = legTrafficInfo.first?.departureDateTime
        let totalTime = legTrafficInfo.first?.totalTime
        
        // 중간 게이지바
        let infos = legTrafficInfo.forEach { info in
            let sectionTime = info.sectionTime // 하나 하나 시간
//            switch info.mode {
//            case .bus:
//                
//            case .subway:
//                
//            case .walk:
//                
//            }
        }
    }
}

final class SegmentProgressView: UIView {
    private var segmentColors: [UIColor] = []
    private var segmentTimes: [CGFloat] = []
    
    private let minimumSegmentWidth: CGFloat = 50
    private let segmentHeight: CGFloat = 16
    private let cornerRadius: CGFloat = 8.0
    private let overlapSpacing: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        backgroundColor = .lightGray
        layer.cornerRadius = cornerRadius
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        clipsToBounds = false
        backgroundColor = .lightGray
        layer.cornerRadius = cornerRadius
    }
    
    func update(times: [CGFloat], colors: [UIColor]) {
        segmentTimes = times
        segmentColors = colors
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        subviews.forEach { $0.removeFromSuperview() }
        
        guard segmentTimes.count > 0 else { return }
        
        let totalTime = segmentTimes.reduce(0, +)
        let segmentCount = CGFloat(segmentTimes.count)
        
        let totalMinWidth = minimumSegmentWidth * segmentCount
        let totalAvailableWidth = max(bounds.width, totalMinWidth)
        
        let ratios = segmentTimes.map { $0 / totalTime }
        let segmentWidths = ratios.map { max(totalAvailableWidth * $0, minimumSegmentWidth) }
        
        let totalOverlap = overlapSpacing * (segmentCount - 1)
        let usedWidth = segmentWidths.reduce(0, +) - totalOverlap
        
        let scalingFactor = min(1.0, bounds.width / usedWidth)
        
        // 모든 segment 를 개별 생성
        var currentX: CGFloat = 0
        
        for (index, width) in segmentWidths.enumerated() {
            let scaledWidth = width * scalingFactor
            let color = segmentColors[index % segmentColors.count]
            let timeValue = segmentTimes[index]
            
            let segmentFrame = CGRect(
                x: currentX,
                y: 0,
                width: scaledWidth,
                height: segmentHeight
            )
            
            let segmentView = UIView(frame: segmentFrame)
            segmentView.backgroundColor = color
            segmentView.layer.cornerRadius = cornerRadius
            segmentView.clipsToBounds = true
            addSubview(segmentView)
            
            // UILabel 추가
            let label = UILabel(frame: segmentView.bounds)
            label.text = String(format: "%.1f분", timeValue)
            label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            label.textColor = (color == .lightGray) ? .black : .white
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            segmentView.addSubview(label)
            
            if index < segmentWidths.count - 1 {
                currentX += scaledWidth - overlapSpacing
            } else {
                currentX += scaledWidth
            }
        }
    }
}

//struct LegTrafficInfo {
//    let departureDateTime: String?
//    let totalTime: String?
//
//    // Legs밑에 있는 애들
//    let sectionTime: String?
//    let mode: TransportMode?
//    let type: String?
//    let passStopList: [passStopList]?
//    let route: String? // "간선:N62"
//
//    let walkDistance: [Step]? // 보행자 이동 거리 (미터)
//}
