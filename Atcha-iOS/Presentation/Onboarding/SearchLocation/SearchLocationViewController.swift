//
//  SearchLocationViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import UIKit
import SnapKit
import SwiftUI

class SearchLocationViewController: BaseViewController<SearchLocationViewModel> {
    
    private let searchNavigationBar: SearchNavigationBar = AtchaNavigationBar.search()
    private let headerView: UIView = UIView()
    private let separator: UIView = UIView()
    private let headerLabel: UILabel = UILabel()
    private var tableViewTopConstraint: Constraint?
    
    private var filteredLocations: [Location] = []
    private let tableView = UITableView()
    private var isSubmitted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        // 실시간 검색 결과 업데이트 시 UI 반영
        viewModel.onLocationsUpdated = { [weak self] locations in
            self?.filteredLocations = locations
            self?.tableView.reloadData()
        }
        
        
        searchNavigationBar.onTapBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        searchNavigationBar.onTextChange = { [weak self] text in
            guard let self = self else { return }
            self.headerView.isHidden = true
            
            self.tableView.snp.remakeConstraints { make in
                make.top.equalTo(self.searchNavigationBar.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
            
            //LocationManager 만들어서 위도 경도 수정할 것
            self.viewModel.searchLocation(keyword: text, lat: 37.556104, lon: 126.972656)
        }
        
        searchNavigationBar.onTextSubmit = { [weak self] text in
            guard let self = self else { return }
            
            self.headerView.isHidden = false
            
            self.tableView.snp.remakeConstraints { make in
                make.top.equalTo(self.headerView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            
            //LocationManager 만들어서 위도 경도 수정할 것
            self.viewModel.searchLocation(keyword: text, lat: 37.556104, lon: 126.972656)
        }
    }
    
    // MARK: - Search Location UI
    private func setupUI() {
        headerView.backgroundColor = .clear
        separator.backgroundColor = AtchaColor.black
        headerLabel.attributedText = AtchaFont.Body_R_14("장소 결과", color: AtchaColor.gray400)
        headerView.addSubViews(separator, headerLabel)
        headerView.isHidden = true
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.addSubViews(searchNavigationBar, headerView, tableView)
        
        searchNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        separator.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.top)
            make.leading.equalTo(headerView.snp.leading)
            make.trailing.equalTo(headerView.snp.trailing)
            make.height.equalTo(10)
        }
        
        headerLabel.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom).offset(14)
            make.leading.equalTo(headerView.snp.leading).inset(16)
        }
        
        headerView.snp.makeConstraints { make in
            make.top.equalTo(searchNavigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(headerLabel.snp.bottom).offset(4)
        }
        
        tableView.snp.makeConstraints { make in
            self.tableViewTopConstraint = make.top.equalTo(searchNavigationBar.snp.bottom).constraint
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension SearchLocationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLocations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let location = filteredLocations[indexPath.row]
        
        // 기존 content 제거
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let titleLabel = UILabel()
        titleLabel.attributedText = AtchaFont.Body_R_15(location.name, color: AtchaColor.white)
        let detailLabel = UILabel()
        detailLabel.attributedText = AtchaFont.Body_R_14(location.address, color: AtchaColor.gray200)
        
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 4
        labelStack.alignment = .leading
        
        cell.contentView.addSubview(labelStack)
        labelStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(19)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = filteredLocations[indexPath.row]
        print("선택한 장소: \(selected)")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredLocations.isEmpty ? 0 : 1
    }
}
