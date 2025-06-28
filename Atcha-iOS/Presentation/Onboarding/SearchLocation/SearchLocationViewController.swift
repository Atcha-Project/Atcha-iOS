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
        
        bind()
        requestCurrentLocation()
        setupUI()
        setupSearchNavigationBarCallbacks()
    }
    
    // MARK: - ViewModel 바인딩
    private func bind() {
        viewModel.$locations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] locations in
                self?.filteredLocations = locations
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
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
    
    // MARK: - 장소 검색 UI
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
    
    // MARK: - 검색 네비게이션 바 콜백
    private func setupSearchNavigationBarCallbacks() {
        searchNavigationBar.onTapBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        searchNavigationBar.onTapCurrentLocation = { [weak self] in
            self?.handleCurrentLocationTapped()
        }
        
        searchNavigationBar.onTextChange = { [weak self] text in
            guard let self = self, let coordinate = self.currentCoordinate else { return }
            self.handleTextChange(text: text, coordinate: coordinate)
        }
        
        searchNavigationBar.onTextSubmit = { [weak self] text in
            guard let self = self, let coordinate = self.currentCoordinate else { return }
            self.handleTextSubmit(text: text, coordinate: coordinate)
        }
    }
    
    // MARK: - 텍스트 변화
    private func handleTextChange(text: String, coordinate: CLLocationCoordinate2D) {
        headerView.isHidden = true
        tableView.snp.remakeConstraints { make in
            make.top.equalTo(searchNavigationBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
        viewModel.searchLocation(keyword: text, lat: coordinate.latitude, lon: coordinate.longitude)
    }

    // MARK: - 텍스트 제출 처리
    private func handleTextSubmit(text: String, coordinate: CLLocationCoordinate2D) {
        headerView.isHidden = false
        tableView.snp.remakeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        viewModel.searchLocation(keyword: text, lat: coordinate.latitude, lon: coordinate.longitude)
    }
}

extension SearchLocationViewController: UITableViewDataSource, UITableViewDelegate {
    
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
    
    // MARK: -  Cell 선택 시 이벤트
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
        
        vc.onRegisterCompleted = { [weak self] name, address, lat, lon in
            if let homeVC = self?.navigationController?.viewControllers.first(where: { $0 is HomeRegisterViewController }) as? HomeRegisterViewController {
                homeVC.viewModel.updateLocation(name: name, address: address, lat: lat, lon: lon)
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredLocations.isEmpty ? 0 : 1
    }
    
    // MARK: - 현위치 찾기
    @objc private func handleCurrentLocationTapped() {
        viewModel.handleCurrentLocation { [weak self] registerVM, coordinate, placeName, address in
            guard let self else { return }
            
            let vc = RegisterLocationViewController(
                viewModel: registerVM,
                coordinate: coordinate,
                placeName: placeName,
                address: address
            )
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
