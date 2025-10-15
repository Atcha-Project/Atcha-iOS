//
//  RouteLineView.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/3/25.
//

import Foundation
import UIKit
import SnapKit

enum RouteCircleType {
    case circle      // 원
    case rotation        // 회차 이미지
}

enum RouteHeightType {
    case short   // 68
    case long    // 107
}

enum RouteLineOpacity {
    case all(CGFloat)      // 전체 라인 opacity
    case top(CGFloat)      // 탑 라인만 opacity
    case bottom(CGFloat)   // 바텀 라인만 opacity
    case none              // 불투명 (기본값)
}

enum RouteLinePosition {
    case topOnly
    case bottomOnly
    case both
    case none
}

final class RouteLineView: UIView {
    
    // MARK: - 버스 노선 기본 세팅
    private let topLine = UIView()
    private let bottomLine = UIView()
    private let circleImageView = UIImageView()
    
    // MARK: - 버스 노선 상태
    private var heightType: RouteHeightType = .short
    private var circleType: RouteCircleType = .circle
    private var lineColor: UIColor = .gray
    private var lineOpacity: RouteLineOpacity = .none
    
    // MARK: - Init
    init(
        heightType: RouteHeightType,
        circleType: RouteCircleType,
        lineColor: UIColor = .gray,
        lineOpacity: RouteLineOpacity = .none
    ) {
        super.init(frame: .zero)
        self.heightType = heightType
        self.circleType = circleType
        self.lineColor = lineColor
        self.lineOpacity = lineOpacity
        
        setupUI()
        applyConfiguration()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 버스 노선 하나의 Cell Configure
    func configure(
        heightType: RouteHeightType,
        circleType: RouteCircleType,
        lineColor: UIColor,
        lineOpacity: RouteLineOpacity,
        linePosition: RouteLinePosition
    ) {
        self.heightType = heightType
        self.circleType = circleType
        self.lineColor = lineColor
        self.lineOpacity = lineOpacity
        
        // 기본 세팅
        topLine.isHidden = false
        bottomLine.isHidden = false
        
        // 위치 조건에 따라 숨김 처리
        switch linePosition {
        case .topOnly:
            bottomLine.isHidden = true
        case .bottomOnly:
            topLine.isHidden = true
        case .both:
            break
        case .none:
            topLine.isHidden = true
            bottomLine.isHidden = true
        }
        applyConfiguration()
    }
    
    // MARK: - Bus Route 하나의 Cell UI
    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = false
        self.layer.zPosition = 0
        
        addSubview(topLine)
        addSubview(bottomLine)
        addSubview(circleImageView) // 원은 라인 위에 올라옴(z-index)
        
        // topLine
        topLine.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(4)
            make.height.equalTo(28) // 기본값 (applyConfiguration에서 업데이트됨)
        }
        
        // bottomLine (topLine과 12 떨어져 있음)
        bottomLine.snp.makeConstraints { make in
            make.top.equalTo(topLine.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.width.equalTo(4)
            make.height.equalTo(28) // 기본값 (applyConfiguration에서 업데이트됨)
            make.bottom.equalToSuperview()
        }
        
        // circle (gap 위에 덮어놓기)
        circleImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(topLine.snp.bottom).offset(6) // 11 간격의 중간
            make.size.equalTo(14)
        }
    }
    
    // MARK: - Bus Route 하나의 Cell Apply Configuration
    private func applyConfiguration() {
        // 라인 색상 적용
        [topLine, bottomLine].forEach { $0.backgroundColor = lineColor }
        
        // opacity 적용
        switch lineOpacity {
        case .all(let alpha):
            topLine.alpha = alpha
            bottomLine.alpha = alpha
        case .top(let alpha):
            topLine.alpha = alpha
            bottomLine.alpha = 1.0
        case .bottom(let alpha):
            topLine.alpha = 1.0
            bottomLine.alpha = alpha
        case .none:
            topLine.alpha = 1.0
            bottomLine.alpha = 1.0
        }
        
        // 높이 업데이트 (합계가 RouteHeightType 높이와 맞도록 조정)
        let (topBottomLength, circleSize): (CGFloat, CGFloat) = {
            switch heightType {
            case .short: return (28, 14)
            case .long:  return (48, 14)
            }
        }()
        
        topLine.snp.updateConstraints { make in
            make.height.equalTo(topBottomLength)
        }
        
        bottomLine.snp.updateConstraints { make in
            make.height.equalTo(topBottomLength)
        }
        
        switch heightType {
        case .short:
            self.snp.updateConstraints { $0.height.equalTo(68) }
        case .long:
            self.snp.updateConstraints { $0.height.equalTo(108) }
        }
        
        // 이미지 적용
        switch circleType {
        case .circle:
            circleImageView.image = .busRouteCircle
            circleImageView.contentMode = .scaleAspectFit
            
            circleImageView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalTo(topLine.snp.bottom).offset(6) // 11 간격의 중간
                make.size.equalTo(14)
            }
            
        case .rotation:
            circleImageView.image = .rotation
            circleImageView.contentMode = .scaleAspectFit
            
            circleImageView.snp.remakeConstraints { make in
                make.centerY.equalTo(topLine.snp.bottom).offset(6)
                make.width.equalTo(36)
                make.height.equalTo(circleSize)
                make.trailing.equalToSuperview().offset(5)
            }
        }
    }
}
