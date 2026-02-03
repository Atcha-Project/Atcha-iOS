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
        } onClose: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }()
    private let headerView: BusDetailHeaderView = BusDetailHeaderView()
    private let refreshButton: RefreshView = RefreshView(background: .default)
    private let loadingView: LoadingView = LoadingView()
    private var didScrollToCurrentStation = false
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.busRouteCollectionView.visibleCells.forEach {
                ($0 as? BusRouteCell)?.ensureBusOnTop()
            }
        }
        
        AmplitudeManager.shared.trackScreen(.bus_detail)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        refreshButton.stop()
        loadingView.stop()
    }
    
    // MARK: - ViewModel 바인딩
    private func bind() {
        viewModel.$busPositionInfo
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] busInfo in
                self?.applySnapshot(busRoute: busInfo)
                let busCount = busInfo.busPositions?.count ?? 0
                self?.headerView.updateBusCount(busCount)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.loadingView.isHidden = true
                }
            }
            .store(in: &cancellables)
        
        viewModel.$isServerError
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isError in
                    guard let self = self else { return }
                    guard isError else { return }

                    self.refreshButton.stop()
                    self.loadingView.stop()
                    self.loadingView.isHidden = true

                }
                .store(in: &cancellables)
    }
    
    // MARK: - 버스 상세 노선 UI
    private func setupUI() {
        view.backgroundColor = AtchaColor.gray950
        
        refreshButton.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onRefreshTapped))
        refreshButton.addGestureRecognizer(tap)
        loadingView.isHidden = true
        view.addSubViews(topNavigationBar, headerView, busRouteCollectionView, refreshButton, loadingView)
    }
    
    // MARK: - 버스 상세 노선 AutoLayout
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
        
        refreshButton.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
        }
        
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Action
    private func bindActions() {
        headerView.onInfoTap = { [weak self] in
            self?.viewModel.didTapInfo()
            AmplitudeManager.shared.track(.bus_info_click)
        }
    }
    
    // MARK: - BusRoute CollectionView DataSource & Cell 바인딩
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
    
//    // MARK: - BusRoute CollectionView Layout
//    private func layout() -> UICollectionViewCompositionalLayout {
//        UICollectionViewCompositionalLayout{ [weak self] section, _ in
//            switch self?.currentSection[section] {
//            case .busRouteList:
//                return BusRouteCell.busRouteLayout()
//            case .none:
//                return nil
//            }
//        }
//    }
    
    // MARK: - BusRoute CollectionView Cell 설정
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
        let isCurrentStation = viewModel.busDetailInfo.targetBusStation?.contains(where: { target in
            target.busStationId == station.busStationId &&
            target.busStationNumber == station.busStationNumber &&
            target.busStationName == station.busStationName
        }) ?? false
        let isAfterTurnPoint = (order > turnPoint)
        
        let stations = viewModel.busPositionInfo?.busRouteStationList ?? []
        let isFirstStation = (station.order == stations.first?.order)
        let isLastStation  = (station.order == stations.last?.order)
        
        if isCurrentStation {
            cell.backgroundColor = AtchaColor.gray930
        } else {
            cell.backgroundColor = .clear
        }
        
        cell.configure(
            with: station,
            isTurnPoint: isTurnPoint,
            isCurrentStation: isCurrentStation,
            busType: busType,
            remainInfo: busesAtStation,
            bus: busPosition,
            isAfterTurnPoint: isAfterTurnPoint,
            isFirstStation: isFirstStation,
            isLastStation: isLastStation
        )
        
        return cell
    }
    
    // MARK: - snapshot 갱신
    private func applySnapshot(busRoute: BusPositionInfo) {
        var snapshot = Snapshot()
        
        snapshot.appendSections([.busRouteList])
        if let stations = busRoute.busRouteStationList {
            snapshot.appendItems(stations, toSection: .busRouteList)
        }
        
        dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            guard let self = self else { return }
            self.busRouteCollectionView.collectionViewLayout.invalidateLayout()
            
            if !didScrollToCurrentStation,
               let stations = busRoute.busRouteStationList,
               let currentStationId = viewModel.busDetailInfo.targetBusStation?.first?.busStationId,
               let currentIndex = stations.firstIndex(where: { $0.busStationId == currentStationId }) {
                
                let indexPath = IndexPath(item: currentIndex, section: 0)
                
                busRouteCollectionView.performBatchUpdates(nil) { [weak self] _ in
                    self?.busRouteCollectionView.scrollToItem(
                        at: indexPath,
                        at: .centeredVertically,
                        animated: false
                    )
                    self?.didScrollToCurrentStation = true
                }
            }
            
            DispatchQueue.main.async {
                self.busRouteCollectionView.performBatchUpdates(nil) { _ in
                    self.busRouteCollectionView.visibleCells.forEach {
                        ($0 as? BusRouteCell)?.ensureBusOnTop()
                    }
                }
            }
        }
    }
    
    // MARK: - 리프레쉬 버튼 함수
    @objc private func onRefreshTapped() {
        refreshButton.start()
        loadingView.isHidden = false
        loadingView.startOnce()
        viewModel.refresh()
    }
    
    private func itemAt(_ indexPath: IndexPath) -> BusRouteStationList? {
        let snap = dataSource.snapshot()
        let items = snap.itemIdentifiers(inSection: .busRouteList)
        guard indexPath.item < items.count else { return nil }
        return items[indexPath.item]
    }

    private func itemHasRealTimeBus(at indexPath: IndexPath) -> Bool {
        guard let station = itemAt(indexPath),
              let order = station.order else { return false }
        let buses = viewModel.busPositionInfo?.busPositions ?? []
        // 셀 configure할 때 쓰던 것과 동일한 기준
        return buses.contains { $0.sectionOrder == order && $0.sectionProgress != nil }
    }
    
    private func layout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] section, _ in
            guard let self = self else { return nil }

            let itemSize  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(68))
            let item      = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(68))
            let group     = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            let section   = NSCollectionLayoutSection(group: group)

            section.visibleItemsInvalidationHandler = { [weak self] items, _, _ in
                guard let self = self else { return }
                for v in items where v.representedElementCategory == .cell {
                    // 기본은 0
                    v.zIndex = 0
                    // 이 indexPath의 역(Station)에 '실시간 버스'가 있으면 높게
                    if self.itemHasRealTimeBus(at: v.indexPath) {
                        v.zIndex = 999
                    }
                }
            }
            return section
        }
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
        let isCurrent = viewModel.busDetailInfo.targetBusStation?.contains(where: { target in
            target.busStationId == station?.busStationId &&
            target.busStationNumber == station?.busStationNumber &&
            target.busStationName == station?.busStationName
        }) ?? false
        return CGSize(width: collectionView.bounds.width,
                      height: isCurrent ? 108 : 68)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        (cell as? BusRouteCell)?.ensureBusOnTop()
    }
}
