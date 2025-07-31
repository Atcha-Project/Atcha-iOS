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
    private lazy var busRouteCollectionView: UICollectionView = {
        let layout = layout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.register(BusRouteCell.self, forCellWithReuseIdentifier: BusRouteCell.reusableId)
        return cv
    }()
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, BusRouteStationList>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, BusRouteStationList>
    private lazy var dataSource: DataSource = setDataSource()
    private var currentSection: [Section] {
        dataSource.snapshot().sectionIdentifiers as [Section]
    }
    private enum Section {
        case busRouteList
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        bind()
        bindActions()
    }
    
    private func bind() {
        viewModel.$busPositionInfo
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] busInfo in
                self?.applySnapshot(busRoute: busInfo)
            }
            .store(in: &cancellables)
    }
    
    private func setupUI() {
        view.backgroundColor = AtchaColor.gray950
        
        view.addSubViews(topNavigationBar, headerView, busRouteCollectionView)
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
        
        busRouteCollectionView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func bindActions() {
        headerView.onInfoTap = { [weak self] in
            self?.viewModel.onInfoTap?()
        }
    }
    
    // MARK: - Course CollectionView DataSource & Cell 바인딩
    private func setDataSource() -> DataSource {
        let dataSource: DataSource = UICollectionViewDiffableDataSource(collectionView: busRouteCollectionView)
        { [weak self] collectionView, indexPath, busInfo in
            switch self?.currentSection[indexPath.section] {
            case .busRouteList:
                return self?.busRouteCell(collectionView, indexPath, busInfo)
            case .none:
                return .init()
            }
        }
        
        return dataSource
    }
    
    // MARK: - Course CollectionView Layout
    private func layout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout{ [weak self] section, _ in
            switch self?.currentSection[section] {
            case .busRouteList:
                return BusRouteCell.busRouteLayout()
            case .none:
                return nil
            }
        }
    }
    
    // MARK: - Course CollectionView Cell 설정
    private func busRouteCell(_ collectionView: UICollectionView, _ indexPath: IndexPath, _ station: BusRouteStationList) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BusRouteCell.reusableId,
            for: indexPath
        ) as? BusRouteCell else {
            return UICollectionViewCell()
        }
        
        let busType = viewModel.busType
        let busesAtStation = viewModel.busRealTimeInfo?.realTimeBusArrival ?? []
        let busPosition = viewModel.busPositionInfo?.busPositions ?? []

        
        let order = station.order ?? 0
        let turnPoint = viewModel.busPositionInfo?.turnPoint ?? 9999
        
        let isTurnPoint = (order == turnPoint)
        let isCurrentStation = (station.busStationName == viewModel.busDetailInfo.start?.name)
        let isAfterTurnPoint = (order > turnPoint) 
        
        cell.configure(
            with: station,
            isTurnPoint: isTurnPoint,
            isCurrentStation: isCurrentStation,
            busType: busType,
            remainInfo: busesAtStation,
            bus: busPosition,
            isAfterTurnPoint: isAfterTurnPoint
        )
        
        return cell
    }
    
    // MARK: - Course Snapshot 갱신
    private func applySnapshot(busRoute: BusPositionInfo) {
        var snapshot = Snapshot()
        
        snapshot.appendSections([.busRouteList])
        if let stations = busRoute.busRouteStationList {
            snapshot.appendItems(stations, toSection: .busRouteList)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension BusDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.busPositionInfo?.busRouteStationList?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let station = viewModel.busPositionInfo?.busRouteStationList?[indexPath.item]
        let isCurrent = (station?.busStationName == viewModel.busDetailInfo.start?.name)
        return CGSize(width: collectionView.bounds.width,
                      height: isCurrent ? 107 : 68)
    }
}
