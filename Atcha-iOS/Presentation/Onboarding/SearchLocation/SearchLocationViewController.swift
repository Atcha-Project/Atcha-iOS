//
//  SearchLocationViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import UIKit
import SnapKit

class SearchLocationViewController: BaseViewController<SearchLocationViewModel> {

    private let searchNavigationBar: SearchNavigationBar = AtchaNavigationBar.search()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
        
    private func setupUI() {
        view.addSubview(searchNavigationBar)
        
        searchNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
    }

}
