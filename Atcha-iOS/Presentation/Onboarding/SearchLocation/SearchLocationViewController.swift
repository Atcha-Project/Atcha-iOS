//
//  SearchLocationViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import UIKit
import SnapKit
import CoreLocation

class SearchLocationViewController: BaseViewController<SearchLocationViewModel> {
    
    private let searchNavigationBar: SearchNavigationBar = AtchaNavigationBar.search()
    private let headerView: UIView = UIView()
    private let separator: UIView = UIView()
    private let headerLabel: UILabel = UILabel()
    private var tableViewTopConstraint: Constraint?
    
    private var filteredLocations: [Location] = []
    private let tableView = UITableView()
    private var isSubmitted = false
    
    private var currentCoordinate: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestCurrentLocation()
        setupUI()
        
        // 실시간 검색 결과 업데이트 시 UI 반영
        viewModel.onLocationsUpdated = { [weak self] locations in
            self?.filteredLocations = locations
            self?.tableView.reloadData()
        }
        
        
        searchNavigationBar.onTapBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        searchNavigationBar.onTapCurrentLocation = { [weak self] in
            self?.handleCurrentLocationButtonTapped()
        }
        
        searchNavigationBar.onTextChange = { [weak self] text in
            guard let self = self, let coordinate = self.currentCoordinate else { return }
            self.headerView.isHidden = true
            
            self.tableView.snp.remakeConstraints { make in
                make.top.equalTo(self.searchNavigationBar.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
            
            self.viewModel.searchLocation(keyword: text, lat: coordinate.latitude, lon: coordinate.longitude)
        }
        
        searchNavigationBar.onTextSubmit = { [weak self] text in
            guard let self = self, let coordinate = self.currentCoordinate else { return }
            
            self.headerView.isHidden = false
            
            self.tableView.snp.remakeConstraints { make in
                make.top.equalTo(self.headerView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            
            self.viewModel.searchLocation(keyword: text, lat: coordinate.latitude, lon: coordinate.longitude)
        }
    }
    
    // MARK: - 현재 위치 요청
    private func requestCurrentLocation() {
        viewModel.onboardingUseCase.requestCurrentLocation { [weak self] coordinate in
            guard let coordinate = coordinate else {
                print("위치 권한 거부됨 또는 위치 불가")
                return
            }
            print("현재 위치 획득: \(coordinate.latitude), \(coordinate.longitude)")
            self?.currentCoordinate = coordinate
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
        
        let coordinate = CLLocationCoordinate2D(latitude: selected.lat, longitude: selected.lon)
        let placeName = selected.name
        let address = selected.address
        
        let registerVM = viewModel.makeRegisterLocationViewModel()
        let vc = RegisterLocationViewController(
            viewModel: registerVM,
            coordinate: coordinate,
            placeName: placeName,
            address: address
        )
        
        vc.onRegisterCompleted = { [weak self] name, address in
            if let homeVC = self?.navigationController?.viewControllers.first(where: { $0 is HomeRegisterViewController }) as? HomeRegisterViewController {
                homeVC.updateLocation(name: name, address: address)
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredLocations.isEmpty ? 0 : 1
    }
    
    @objc private func handleCurrentLocationButtonTapped() {
        viewModel.onboardingUseCase.requestCurrentLocation { [weak self] coordinate in
            guard let self = self, let coordinate = coordinate else {
                print("❌ 현재 위치 가져오기 실패")
                return
            }
            
            Task {
                do {
                    let response = try await self.viewModel.reverseGeocodeLocation(
                        lat: coordinate.latitude,
                        lon: coordinate.longitude
                    )
                    
                    let placeName = response.name
                    let address = response.address
                    
                    let registerVM = self.viewModel.makeRegisterLocationViewModel()
                    let vc = RegisterLocationViewController(
                        viewModel: registerVM,
                        coordinate: coordinate,
                        placeName: placeName,
                        address: address
                    )
                    DispatchQueue.main.async {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                } catch {
                    print("❌ 장소 변환 실패: \(error)")
                }
            }
        }
    }
}
