//
//  SearchLocationViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import UIKit
import SnapKit
import CoreLocation

final class SearchLocationViewController: BaseViewController<SearchLocationViewModel> {
    private let searchNavigationBar: SearchNavigationBar = AtchaNavigationBar.search()
    private let headerView: UIView = UIView()
    private let separator: UIView = UIView()
    private let headerLabel: UILabel = UILabel()
    private let tableView = UITableView()
    
    private var tableViewTopConstraint: Constraint?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async { [weak self] in
            self?.searchNavigationBar.focusTextField()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        bindViewModel()
        setupSearchNavigationBarCallbacks()
    }
    
    // MARK: - ViewModel 바인딩
    private func bindViewModel() {
        viewModel.$locations
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] locations in
                guard let self else { return }
                tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 장소 검색 UI
    private func setupUI() {
        view.addSubViews(searchNavigationBar, headerView, tableView)
        headerView.addSubViews(separator, headerLabel)
        headerView.backgroundColor = .clear
        headerLabel.attributedText = AtchaFont.B6_R_14("장소 결과", color: AtchaColor.gray400)
        headerView.isHidden = true
        
        separator.backgroundColor = AtchaColor.black
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    private func setupAutoLayout() {
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
            guard let self = self else { return }
            let coordinate = viewModel.currentLocation ?? CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
            self.handleTextChange(text: text, coordinate: coordinate)
        }
        
        searchNavigationBar.onTextSubmit = { [weak self] text in
            guard let self = self, let coordinate = viewModel.currentLocation else { return }
            self.handleTextSubmit(text: text, coordinate: coordinate)
        }
        
        searchNavigationBar.onBeginEditing = { [weak self] in
            print("키보드 사용")
        }
        searchNavigationBar.onEndEditing = { [weak self] in
            print("키보드 중지")
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
        
        viewModel.searchLocation(keyword: text,
                                 lat: coordinate.latitude,
                                 lon: coordinate.longitude)
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.locations.count
    }
    
    // MARK: - Cell UI
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let location = viewModel.selectedLocation(at: indexPath)
        
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let titleLabel = UILabel()
        titleLabel.attributedText = AtchaFont.B4_R_15(location.name ?? "이름 없음", color: AtchaColor.white)
        let detailLabel = UILabel()
        let addressText = "\(location.radius ?? "" ) • \(location.address ?? "주소 없음")"
        detailLabel.attributedText = AtchaFont.B6_R_14(addressText, color: AtchaColor.gray200)
        
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
        let location = viewModel.selectedLocation(at: indexPath)

        Task { [weak self] in
            guard let self else { return }
            let ok = await viewModel.checkServiceRegion(lat: location.lat, lon: location.lon)

            if ok {
                viewModel.saveNewLocation(location: location)
            } else {
                AtchaToast(message: "앗차는 현재 서울, 경기, 인천에서만 이용 가능해요")
                    .show(in: self.view)
            }
        }
    }
    
    @objc private func handleCurrentLocationTapped() {
        viewModel.routeHandler?(.homeRegister(useDeviceLocation: true))
    }
}
