//
//  BusDetailViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/29/25.
//

import UIKit
import Combine
import SnapKit

class BusDetailViewController: BaseViewController<BusDetailViewModel> {
    
    private lazy var topNavigationBar: IconTitleNavigationBar = {
        AtchaNavigationBar.iconTitle(
            viewModel.busNumber,
            viewModel.icon
        ) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        } onClose: {
        }
    }()
    private let headerView: BusDetailHeaderView = BusDetailHeaderView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        bindActions()
    }
    
    private func setupUI() {
        view.backgroundColor = AtchaColor.gray950
        
        view.addSubViews(topNavigationBar, headerView)
    }
    
    private func setupAutoLayout() {
        
        topNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.trailing.leading.equalToSuperview()
        }
        
        headerView.snp.makeConstraints { make in
            make.top.equalTo(topNavigationBar.snp.bottom)
            make.trailing.leading.equalToSuperview()
            make.height.equalTo(42)
        }
    }
    
    private func bindActions() {
        headerView.onInfoTap = { [weak self] in
            self?.viewModel.onInfoTap?()
        }
    }
}
