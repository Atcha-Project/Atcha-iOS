//
//  SearchLocationViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import UIKit
import SnapKit
import SwiftUI

struct Location {
    let name: String
    let detail: String
}

class SearchLocationViewController: BaseViewController<SearchLocationViewModel> {
    
    private let searchNavigationBar: SearchNavigationBar = AtchaNavigationBar.search()
    private let headerView: UIView = UIView()
    private let separator: UIView = UIView()
    private let headerLabel: UILabel = UILabel()
    private var tableViewTopConstraint: Constraint?
    
    //테스트 용
    private var allLocations: [Location] = [
        Location(name: "서울역", detail: "1.9km ㆍ 서울시 중구 세종대로 1"),
        Location(name: "서울역 롯데몰", detail: "1.9km ㆍ 서울시 중구 청파로 426"),
        Location(name: "서울역 지하쇼핑센터", detail: "1.8km ㆍ 서울시 중구 통일로 20"),
        Location(name: "서울역 공항철도", detail: "2.0km ㆍ 서울시 용산구 한강대로 405"),
        Location(name: "서울역 카페", detail: "1.7km ㆍ 서울시 중구 만리재로 201"),
        Location(name: "서울역 스터디룸", detail: "1.6km ㆍ 서울시 중구 만리동2가 50"),
        Location(name: "서울역 버거킹", detail: "1.5km ㆍ 서울시 중구 세종대로 12"),
        Location(name: "서울역 고속터미널", detail: "3.2km ㆍ 서울시 서초구 신반포로 194")
    ]
    
    private var filteredLocations: [Location] = []
    private let tableView = UITableView()
    private var isSubmitted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
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
            
            self.filterList(with: text, isSubmitted: false)
        }
        
        searchNavigationBar.onTextSubmit = { [weak self] text in
            guard let self = self else { return }
            
            self.headerView.isHidden = false
            
            self.tableView.snp.remakeConstraints { make in
                make.top.equalTo(self.headerView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            
            self.filterList(with: text, isSubmitted: true)
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
    
    
    // MARK: - 검색 필터 Method
    private func filterList(with keyword: String, isSubmitted: Bool = false) {
        self.isSubmitted = isSubmitted
        
        if keyword.isEmpty {
            filteredLocations = []
        } else {
            let matches = allLocations.filter { $0.name.contains(keyword) }
            filteredLocations = matches
        }
        
        tableView.reloadData()
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
        detailLabel.attributedText = AtchaFont.Body_R_14(location.detail, color: AtchaColor.gray200)
        
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
