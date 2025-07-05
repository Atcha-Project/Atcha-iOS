//
//  CourseModifyViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/3/25.
//

import UIKit
import SnapKit

class CourseModifyViewController: BaseViewController<CourseModifyViewModel> {
    private let topNavigationBar: BackOnlyNavigationBar = AtchaNavigationBar.backOnly(onBack: {
        
    }, tintColor: AtchaColor.gray300)
    private let searchContainer: UIStackView = UIStackView()
    private let searchTextField: SearchTextField = AtchaTextField.searchTextField { String in
        
    } onTextReset: {
        
    }
    private let mapImageView: UIImageView = UIImageView()
    private let homeContainer: UIStackView = UIStackView()
    private let homeDot: UIView = UIView()
    private let homeLabel: UILabel = UILabel()
    private let separator: UIView = UIView()
    private var filteredLocations: [Location] = []
    private let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    // MARK: - 경로 수정 UI
    private func setupUI() {
        view.backgroundColor = AtchaColor.gray950
        
        mapImageView.image = UIImage.map28Px
        mapImageView.tintColor = AtchaColor.gray200
        mapImageView.contentMode = .scaleAspectFit
        
        searchContainer.addArrangedSubview(searchTextField)
        searchContainer.addArrangedSubview(mapImageView)
        searchContainer.axis = .horizontal
        searchContainer.spacing = 6
        searchContainer.alignment = .center
        
        homeDot.backgroundColor = AtchaColor.white
        homeDot.layer.cornerRadius = 2
        homeDot.contentMode = .scaleAspectFit
        homeLabel.attributedText = AtchaFont.B1_R_17("도착지: 우리집", color: AtchaColor.white)
        homeContainer.addArrangedSubview(homeDot)
        homeContainer.addArrangedSubview(homeLabel)
        homeContainer.axis = .horizontal
        homeContainer.spacing = 10
        homeContainer.alignment = .center
        
        separator.backgroundColor = AtchaColor.black
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.addSubViews(topNavigationBar, searchContainer, homeContainer, separator, tableView)
        
        topNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        
        searchContainer.snp.makeConstraints { make in
            make.top.equalTo(topNavigationBar.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }

        mapImageView.snp.makeConstraints { make in
            make.size.equalTo(28)
        }
        
        homeContainer.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(18)
            make.leading.equalTo(searchContainer.snp.leading).offset(16)
            make.height.equalTo(24)
        }
        
        homeDot.snp.makeConstraints { make in
            make.size.equalTo(4)
        }
        
        separator.snp.makeConstraints { make in
            make.top.equalTo(homeContainer.snp.bottom).offset(22)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(10)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension CourseModifyViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Cell 갯수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLocations.count
    }
    
    // MARK: - Cell UI
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let location = filteredLocations[indexPath.row]
        
        // 기존 content 제거
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let titleLabel = UILabel()
        titleLabel.attributedText = AtchaFont.B4_R_15(location.name ?? "이름 없음", color: AtchaColor.white)
        let detailLabel = UILabel()
        detailLabel.attributedText = AtchaFont.B6_R_14(location.address ?? "주소 없음", color: AtchaColor.gray200)
        
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
    
    // MARK: -  Cell 선택 시 이벤트
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = filteredLocations[indexPath.row]
        print("선택한 장소: \(selected)")
        
        if let lat = selected.lat,
           let lon = selected.lon,
           let placeName = selected.name,
           let address = selected.address {
            
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredLocations.isEmpty ? 0 : 1
    }
}
