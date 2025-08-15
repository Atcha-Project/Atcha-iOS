//
//  AtchaPopupViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/23/25.
//

import UIKit

final class AtchaPopupViewController: BaseViewController<AtchaPopupViewModel> {
    private let titleLabel: UILabel = UILabel()
    let cancelButton: UIButton = UIButton(type: .system)
    let confirmButton: UIButton = UIButton(type: .system)
    private let containerView: UIView = UIView()
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [cancelButton, confirmButton])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        setupUI()
        setupAutoLayout()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = .black.withAlphaComponent(0.76)
        view.addSubViews(containerView)
        containerView.addSubViews(titleLabel, buttonStackView)
        
        titleLabel.textAlignment = .center
        containerView.backgroundColor = .gray940
        containerView.layer.cornerRadius = 20
        cancelButton.setCornerRadius(8)
        confirmButton.setCornerRadius(8)
    }
    
    private func setupAutoLayout() {
        containerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(30)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.top).inset(32)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
        }
        
        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.horizontalEdges.equalTo(containerView.snp.horizontalEdges).inset(24)
            make.bottom.equalTo(containerView.snp.bottom).inset(32)
            make.height.equalTo(44)
        }
    }
    
    private func bindViewModel() {
        viewModel.$info
            .receive(on: RunLoop.main)
            .sink { [weak self] info in
                guard let self else { return }
                setupPopup(info)
            }
            .store(in: &cancellables)
    }
    
    private func setupPopup(_ info: AtcahPopuInfo) {
        titleLabel.attributedText = AtchaFont.H4_SB_17(info.title, color: .white)
        let cancelAttr  = AtchaFont.B5_SB_14(info.cancelTitle,
                                             color: info.cancelForegroundColor)
        
        let confirmAttr = AtchaFont.B5_SB_14(info.confrimTitle,
                                             color: info.confrimForegroundColor)
        
        cancelButton.setAttributedTitle(cancelAttr,  for: .normal)
        confirmButton.setAttributedTitle(confirmAttr, for: .normal)
        cancelButton.backgroundColor = info.cancelBackgroundColor
        confirmButton.backgroundColor = info.confrimBackgroundColor
    }
}
