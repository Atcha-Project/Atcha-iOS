//
//  CourseModifyViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/3/25.
//

import UIKit
import SnapKit
import CoreLocation

final class CourseModifyViewController: BaseViewController<CourseModifyViewModel> {
    private lazy var topNavigationBar: BackOnlyNavigationBar = AtchaNavigationBar.backOnly(onBack: { [weak self] in
        self?.navigationController?.popViewController(animated: true)
    }, tintColor: AtchaColor.gray300)
    private let searchContainer: UIStackView = UIStackView()
    private let searchTextField: SearchTextField = AtchaTextField.searchTextField()
    private let mapImageView: UIImageView = UIImageView()
    private let homeContainer: UIStackView = UIStackView()
    private let homeDot: UIView = UIView()
    private let homeLabel: UILabel = UILabel()
    private let separator: UIView = UIView()
    private var items: [SearchResultItem] = []
    private let tableView: UITableView = UITableView()
    private var tableViewTopConstraint: Constraint?
    private let tableHeaderView: UIView = UIView()
    private let recentLabel: UILabel = UILabel()
    private let recentAllDeleteLabel: UILabel = UILabel()
    private let emptyRecentLabel: UILabel = UILabel()
    private var isFromSetting: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        bindViewModel()
        viewModel.recentSearchLocation()
        setupSearchTextFieldCallbacks()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async { [weak self] in
            self?.searchTextField.focusTextField()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard !isFromSetting else {
            isFromSetting = false
            return
        }
        
        tableView.isHidden = false
        tableHeaderView.isHidden = false
        let text = searchTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
        
        guard !text.isEmpty,
              let coordinate = viewModel.currentLocation else { return }
        
        viewModel.searchLocation(keyword: text,
                                 lat: coordinate.latitude,
                                 lon: coordinate.longitude)
    }
    
    // MARK: - ViewModel 바인딩
    private func bindViewModel() {
        viewModel.$items
            .receive(on: RunLoop.main)
            .sink { [weak self] newItems in
                guard let self else { return }
                self.items = newItems
                
                switch viewModel.mode {
                case .recent:
                    if viewModel.items.isEmpty {
                        tableHeaderView.isHidden = true
                        emptyRecentLabel.isHidden = false
                    } else {
                        tableHeaderView.isHidden = false
                        emptyRecentLabel.isHidden = true
                    }
                    tableViewTopConstraint?.update(offset: 0)
                case .result:
                    tableHeaderView.isHidden = true
                    emptyRecentLabel.isHidden = true
                    tableViewTopConstraint?.update(offset: -(tableHeaderView.frame.height))
                }
                
                tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 경로 수정 UI
    private func setupUI() {
        view.backgroundColor = AtchaColor.gray950
        
        mapImageView.image = UIImage.map28Px
        mapImageView.tintColor = AtchaColor.gray200
        mapImageView.contentMode = .scaleAspectFit
        mapImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapMapIcon))
        mapImageView.addGestureRecognizer(tap)
        
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
        
        recentLabel.attributedText = AtchaFont.B6_R_14("최근 내역", color: AtchaColor.gray400)
        recentAllDeleteLabel.attributedText = AtchaFont.B6_R_14("전체 삭제", color: AtchaColor.gray400)
        recentAllDeleteLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapDeleteAll))
        recentAllDeleteLabel.addGestureRecognizer(tapGesture)
        
        tableHeaderView.addSubViews(recentLabel, recentAllDeleteLabel)
        
        emptyRecentLabel.attributedText = AtchaFont.B4_R_15("최근 내역이 없습니다.", color: AtchaColor.gray400)
        
        view.addSubViews(topNavigationBar, searchContainer, homeContainer, separator, tableView, tableHeaderView, emptyRecentLabel)
    }
    
    // MARK: - 경로 수정 AutoLayout
    private func setupAutoLayout() {
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
        
        tableHeaderView.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }
        
        recentLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
        }
        
        recentAllDeleteLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().inset(16)
        }
        
        tableView.snp.makeConstraints { make in
            self.tableViewTopConstraint = make.top.equalTo(tableHeaderView.snp.bottom).constraint
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        emptyRecentLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - 검색 바 콜백
    private func setupSearchTextFieldCallbacks() {
        searchTextField.onTextChange = { [weak self] text in
            guard let self = self, let coordinate = viewModel.currentLocation else { return }
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                viewModel.recentSearchLocation()
            } else {
                viewModel.searchLocation(keyword: text,
                                         lat: coordinate.latitude,
                                         lon: coordinate.longitude)
            }
        }
        
        searchTextField.onTextReset = { [weak self] in
            self?.viewModel.recentSearchLocation()
        }
    }
    
    // MARK: - 최근 검색 전체 삭제 메서드
    @objc private func didTapDeleteAll() {
        viewModel.clearAllSearchHistories()
    }
    
    // MARK: - 최근 검색 삭제 메서드
    @objc private func didTapDeleteRecent(_ sender: DeleteTapGestureRecognizer) {
        guard let location = sender.location else { return }
        
        let request = RecentSearchRequest(
            name: location.name,
            lat: location.lat,
            lon: location.lon,
            businessCategory: location.businessCategory,
            address: location.address
        )
        
        viewModel.deleteSearchHistory(request: request)
    }
    
//    func didReceiveLocation(locationInfo: LocationInfo, coordinate: CLLocationCoordinate2D) {
//        isFromSetting = true
//        
//        searchTextField.setText(locationInfo.name ?? "주소 없음")
//        tableView.isHidden = true
//        tableHeaderView.isHidden = true
//        
//        self.showLoading()
//        
//        // 1초 후 ViewModel에게 전달
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            self.hideLoading()
//            self.viewModel.onLocationConfirmed?(locationInfo, coordinate)
//        }
//    }
    
    @objc private func didTapMapIcon() {
        view.endEditing(true)
        guard let loc = viewModel.initialLocation else { return }
        viewModel.onLocationSelected?(loc)
    }
}

extension CourseModifyViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Cell 갯수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    // MARK: - Cell UI
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        // 기존 content 제거
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let titleLabel = UILabel()
        let detailLabel = UILabel()
        
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 4
        labelStack.alignment = .leading
        
        let deleteImageViewImage = UIImageView()
        deleteImageViewImage.image = UIImage.xGray
        deleteImageViewImage.contentMode = .scaleAspectFit
        deleteImageViewImage.isUserInteractionEnabled = true
        
        switch item {
        case .recent(location: let location):
            titleLabel.attributedText = AtchaFont.B4_R_15(location.name ?? "이름 없음", color: AtchaColor.white)
            
            let addressText = "\(location.radius ?? "" ) • \(location.address ?? "주소 없음")"
            detailLabel.attributedText = AtchaFont.B6_R_14(addressText, color: AtchaColor.gray200)
            
            let recentStack = UIStackView(arrangedSubviews: [labelStack, deleteImageViewImage])
            recentStack.axis = .horizontal
            recentStack.spacing = 12
            
            cell.contentView.addSubview(recentStack)
            
            recentStack.snp.makeConstraints {
                $0.top.bottom.equalToSuperview().inset(19)
                $0.leading.trailing.equalToSuperview().inset(16)
            }
            
            let tapGesture = DeleteTapGestureRecognizer(target: self, action: #selector(didTapDeleteRecent(_:)))
            tapGesture.location = location
            deleteImageViewImage.addGestureRecognizer(tapGesture)
            
        case .result(location: let location):
            titleLabel.attributedText = AtchaFont.B4_R_15(location.name ?? "이름 없음", color: AtchaColor.white)
            
            let addressText = "\(location.radius ?? "" ) • \(location.address ?? "주소 없음")"
            detailLabel.attributedText = AtchaFont.B6_R_14(addressText, color: AtchaColor.gray200)
            
            cell.contentView.addSubview(labelStack)
            labelStack.snp.makeConstraints {
                $0.top.bottom.equalToSuperview().inset(19)
                $0.leading.trailing.equalToSuperview().inset(16)
            }
        }
        
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }
    
    // MARK: -  Cell 선택 시 이벤트
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        switch item {
        case .recent(let loc):
            viewModel.addRecentSearchLocation(request: RecentSearchRequest(name: loc.name, lat: loc.lat, lon: loc.lon, businessCategory: loc.businessCategory, address: loc.address))
            
            viewModel.onLocationSelected?(loc)
            
        case .result(let loc):
            Task { [weak self] in
                guard let self else { return }
                let ok = await viewModel.checkServiceRegion(lat: loc.lat, lon: loc.lon)

                if ok {
                    viewModel.addRecentSearchLocation(request: RecentSearchRequest(name: loc.name, lat: loc.lat, lon: loc.lon, businessCategory: loc.businessCategory, address: loc.address))
                    
                    viewModel.onLocationSelected?(loc)
                } else {
                    AtchaToast(message: "앗차는 현재 서울, 경기, 인천에서만 이용 가능해요")
                        .show(in: self.view)
                }
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
}

class DeleteTapGestureRecognizer: UITapGestureRecognizer {
    var location: Location?
}
