//
//  ProximityViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/18/25.
//

import UIKit

final class ProximityViewController: BaseViewController<ProximityViewModel> {
    private let dimView = UIView()
    private let containerView = UIView()
    
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
        setupDim()
        setupContainer()
        setupUI()
        setupAutoLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        dimView.alpha = 1
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        containerView.addSubViews(labelStackView, button)

        titleLabel.attributedText =
            AtchaFont.H4_SB_17("이동하려는 거리가 매우 가까워요", color: .white)
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .left
        

        subTitleLabe.attributedText =
            AtchaFont.B6_R_14("출발지를 확인한 후 다시 검색해 주세요", color: .gray200)
        subTitleLabe.numberOfLines = 1
        subTitleLabe.textAlignment = .left

        button.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
    }
    
    private func setupDim() {
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        dimView.alpha = 0
        view.addSubview(dimView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapConfirm))
        dimView.addGestureRecognizer(tap)
    }
    
    private func setupContainer() {
        containerView.backgroundColor = .gray940
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        view.addSubview(containerView)
    }
    
    private func setupAutoLayout() {
        dimView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        containerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(182)
        }

        labelStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        button.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview().inset(40)
        }
    }
    
    @objc private func didTapConfirm() {
        dimView.alpha = 0
        dismiss(animated: true)
    }
}
