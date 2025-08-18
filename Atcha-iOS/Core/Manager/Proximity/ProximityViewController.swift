//
//  ProximityViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/18/25.
//

import UIKit
import PanModal

final class ProximityViewController: BaseViewController<ProximityViewModel> {
    private let titleLabel: UILabel = UILabel()
    private let subTitleLabe: UILabel = UILabel()

    
    private lazy var labelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subTitleLabe])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        return stackView
    }()
    
    
    private let button: AtchaButton = AtchaButton(text: "확인", size: .h48, style: .filled(.primary))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
    }
    
    private func setupUI() {
        view.backgroundColor = .gray940
        view.addSubViews(labelStackView, button)
        
        titleLabel.attributedText = AtchaFont.H4_SB_17("이동하려는 거리가 매우 가까워요", color: .white)
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .left
        
        subTitleLabe.attributedText = AtchaFont.B6_R_14("출발지를 확인한 후 다시 검색해 주세요", color: .gray200)
        subTitleLabe.numberOfLines = 1
        subTitleLabe.textAlignment = .left
        
        button.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
    }
    
    private func setupAutoLayout() {
        labelStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        
        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-40)
        }
    }
    
    @objc private func didTapConfirm() {
            dismiss(animated: true)
    }
}


extension ProximityViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    var shortFormHeight: PanModalHeight {
        return .contentHeight(170)
    }
    
    // 확장 가능 높이: longFormHeight
    var longFormHeight: PanModalHeight {
        return .contentHeight(170)
    }
}
