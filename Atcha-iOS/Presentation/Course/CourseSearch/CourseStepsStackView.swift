//
//  CourseStepView.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/4/25.
//

import Foundation
import UIKit
import SnapKit

enum CourseStepLayoutType: Hashable {
    case transport(TransportMode)
    case end
}


final class CourseStepsStackView: UIStackView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        axis = .vertical
        spacing = 8
        alignment = .fill
        distribution = .fill
    }

    func configure(legs: [Legs]) {
        arrangedSubviews.forEach { $0.removeFromSuperview() }

        let filtered = legs.filter { $0.mode != .walk }

        for (index, leg) in filtered.enumerated() {
            let isLast = index == filtered.count - 1

            let stepView = CourseStepItemView()
            stepView.configure(leg: leg, isLast: isLast)
            addArrangedSubview(stepView)
        }
    }
}


