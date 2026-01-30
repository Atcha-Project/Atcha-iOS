//
//  DetailRouteProgressView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/30/25.
//

import UIKit

final class DetailRouteProgressView: UIView {
    private var segmentColors: [UIColor] = []
    private var segmentTimes: [CGFloat] = []
    
    private let minimumSegmentWidth: CGFloat = 50
    private let segmentHeight: CGFloat = 16
    private let cornerRadius: CGFloat = 8.0
    private let overlapSpacing: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        backgroundColor = .gray930
        layer.cornerRadius = cornerRadius
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        clipsToBounds = false
        backgroundColor = .gray930
        layer.cornerRadius = cornerRadius
    }
    
    func configure(infos: [LegTrafficInfo]) {
        var times: [CGFloat] = []
        var colors: [UIColor] = []
        
        infos.forEach { info in
            if let sectionTime = info.sectionTime,
               let minutes = parseMinutes(from: sectionTime) {
                times.append(CGFloat(minutes))
            }
            
            if let color = info.mode?.getGageColor(for: info.type ?? "") {
                colors.append(color)
            }
        }
        
        update(times: times, colors: colors)
    }
    
    private func update(times: [CGFloat], colors: [UIColor]) {
        segmentTimes = times
        segmentColors = colors
        setNeedsLayout()
    }
    
    private func parseMinutes(from string: String) -> Int? {
        let clean = string.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        
        if let value = Double(clean), Int(value.rounded()) > 0 {
            return Int(value.rounded())
        }
        return nil
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
            
            let roundedMinutes = Int(timeValue.rounded())
            let timeText = "\(roundedMinutes)분"
            
            let label = UILabel(frame: segmentView.bounds)
            label.attributedText = AtchaFont.M_9(timeText)
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.textColor = color == .gray930 ? .gray400 : .white
            segmentView.addSubview(label)
            
            
            if index < segmentWidths.count - 1 {
                currentX += scaledWidth - overlapSpacing
            } else {
                currentX += scaledWidth
            }
        }
    }
}
