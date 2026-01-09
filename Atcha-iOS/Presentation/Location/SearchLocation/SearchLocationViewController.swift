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
    private let separator: UIView = UIView()
    private let tableView = UITableView()
    private var didFocusOnce = false
    
    private var tableViewTopConstraint: Constraint?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didFocusOnce {
            DispatchQueue.main.async { [weak self] in
                self?.searchNavigationBar.focusTextField()
            }
            didFocusOnce = true
        }
        
        if #available(iOS 16.0, *) {
            view.keyboardLayoutGuide.followsUndockedKeyboard = true
        }
        
        AmplitudeManager.shared.trackScreen(.home_search)
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
                tableView.snp.remakeConstraints { make in
                    make.top.equalTo(self.separator.snp.bottom).offset(self.viewModel.isSectioned ? 14 : 0)
                    make.leading.trailing.bottom.equalToSuperview()
                }
                
                tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 장소 검색 UI
    private func setupUI() {
        view.addSubViews(searchNavigationBar, separator, tableView)
        
        separator.backgroundColor = AtchaColor.black
        separator.isHidden = true
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.keyboardDismissMode = .onDrag
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.estimatedSectionHeaderHeight = 0
    }
    
    private func setupAutoLayout() {
        searchNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        separator.snp.makeConstraints { make in
            make.top.equalTo(searchNavigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(10)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchNavigationBar.snp.bottom)
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
            
            separator.isHidden = true
            
            tableView.snp.remakeConstraints { make in
                make.top.equalTo(self.separator.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
        }
        
        searchNavigationBar.onTextSubmit = { [weak self] in
            guard let self else { return }
            self.viewModel.prioritizeRegionInCurrentResults()
            
            separator.isHidden = false
            
            tableView.snp.remakeConstraints { make in
                make.top.equalTo(self.separator.snp.bottom).offset(14)
                make.leading.trailing.bottom.equalToSuperview()
            }
            
            self.tableView.reloadData()
        }
    }
    
    // MARK: - 텍스트 변화
    private func handleTextChange(text: String, coordinate: CLLocationCoordinate2D) {
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
}

extension SearchLocationViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return viewModel.numberOfRows(in: section)
    }
    
    // MARK: - Cell UI
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let location = viewModel.item(at: indexPath)
        
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let titleLabel = UILabel()
        titleLabel.attributedText = AtchaFont.B4_R_15(location.name ?? "이름 없음", color: AtchaColor.white)
        
        let labelStack = UIStackView(arrangedSubviews: [titleLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 4
        labelStack.alignment = .leading
        
        
        if location.businessCategory?.contains("지역") == false && location.businessCategory != (",") {
            let detailLabel = UILabel()
            let addressText = "\(location.radius ?? "" ) • \(location.address ?? "주소 없음")"
            detailLabel.attributedText = AtchaFont.B6_R_14(addressText, color: AtchaColor.gray200)
            labelStack.addArrangedSubview(detailLabel)
        }
        
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
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForHeader(in: section)
    }
    
    func tableView(_ tableView: UITableView,
                   willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.contentView.backgroundColor = AtchaColor.gray950
        header.backgroundView?.backgroundColor = AtchaColor.gray950
        header.textLabel?.textColor = AtchaColor.gray400
    }
    
    @objc private func handleCurrentLocationTapped() {
        viewModel.routeHandler?(.homeRegister(useDeviceLocation: true))
    }
}
