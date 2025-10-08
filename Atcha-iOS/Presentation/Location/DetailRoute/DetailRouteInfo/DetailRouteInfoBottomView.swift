//
//  DetailRouteInfoBottomView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import UIKit

final class DetailRouteInfoBottomView: UIView {
    enum SheetState {
        case expanded
        case collapsed
    }
    
    enum Section: Hashable {
        case item(UUID)
    }
    
    private var parentViewHeight: CGFloat {
        return superview?.frame.height ?? UIScreen.main.bounds.height
    }
    
    private var collapsedHeight: CGFloat {
        return parentViewHeight * 0.5
    }
    
    private var expandedHeight: CGFloat {
        return parentViewHeight * 0.85
    }
    
    private let routerInfo: [LegTrafficInfo] = []
    private var snapshot = NSDiffableDataSourceSnapshot<Section, LegTrafficUIInfo>()
    private var dataSource: UICollectionViewDiffableDataSource<Section, LegTrafficUIInfo>!
    private var collectionView: UICollectionView!
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var currentState: SheetState = .collapsed
    
    private let handleView: UIView = UIView()
    private var startAddress: String = ""
    private var busRealTimeInfo: [RealTimeBusArrival] = []
    var onBusDetail: ((BusDetailInfo) -> Void)?
    var getNewBusRealTime: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupPanGesture()
        setupAutoLayout()
        setupCollectionView()
        setupDataSource()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupPanGesture()
        setupAutoLayout()
        setupCollectionView()
        setupDataSource()
    }
    
    private func setupView() {
        addSubViews(handleView)
        
        backgroundColor = .gray950
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        handleView.backgroundColor = .gray700
    }
    
    private func setupAutoLayout() {
        handleView.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(4)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(12)
        }
    }
    
    func setupRouteInfo(_ infos: [LegTrafficInfo]) {
        snapshot = NSDiffableDataSourceSnapshot<Section, LegTrafficUIInfo>()
        
        // ✅ 1. Summary Section
        let summarySection = Section.item(UUID())
        snapshot.appendSections([summarySection])
        snapshot.appendItems([
            LegTrafficUIInfo(type: .summary, info: nil, routeInfos: infos)
        ], toSection: summarySection)
        
        // ✅ 2. Start Section (첫 번째 info 사용)
        if let firstInfo = infos.first {
            let startSection = Section.item(UUID())
            snapshot.appendSections([startSection])
            snapshot.appendItems([
                LegTrafficUIInfo(type: .start, info: firstInfo)
            ], toSection: startSection)
        }
        
        // ✅ 3. Transport Sections (각 교통 수단마다 한 섹션)
        for info in infos {
            let transportSection = Section.item(UUID())
            snapshot.appendSections([transportSection])
            
            let transportType: DetailRouteInfoLayoutType = {
                switch info.mode {
                case .walk: return .transport(.walk)
                case .bus: return .transport(.bus)
                case .subway: return .transport(.subway)
                default: return .transport(.unknown)
                }
            }()
            
            let transportItem = LegTrafficUIInfo(type: transportType, info: info)
            snapshot.appendItems([transportItem], toSection: transportSection)
        }
        
        // ✅ 4. End Section (마지막 info 사용)
        if let lastInfo = infos.last {
            let endSection = Section.item(UUID())
            snapshot.appendSections([endSection])
            snapshot.appendItems([
                LegTrafficUIInfo(type: .end, info: lastInfo)
            ], toSection: endSection)
        }
        
        applySnapshot()
    }
    
    // v2
    func setupBusTimerLabel(_ time: [RealTimeBusArrival]) {
        busRealTimeInfo = time
        collectionView.reloadData()
    }
    
    func setupStartAddress(_ address: String) {
        startAddress = address
        collectionView.reloadData()
    }
    
    private func applySnapshot(animatingDifferences: Bool = true) {
        guard collectionView.dataSource != nil else { return }
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}

// MARK: - CollectionView
extension DetailRouteInfoBottomView {
    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        addSubview(collectionView)
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(handleView.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .gray950
        collectionView.register(DetailRouteStartCell.self, forCellWithReuseIdentifier: DetailRouteStartCell.id)
        collectionView.register(DetailRouteSummaryCell.self, forCellWithReuseIdentifier: DetailRouteSummaryCell.id)
        collectionView.register(DetailRouteEndCell.self, forCellWithReuseIdentifier: DetailRouteEndCell.id)
        collectionView.register(DetailRouteWalkCell.self, forCellWithReuseIdentifier: DetailRouteWalkCell.id)
        collectionView.register(DetailRouteBusCell.self, forCellWithReuseIdentifier: DetailRouteBusCell.id)
        collectionView.register(DetailRouteSubwayCell.self, forCellWithReuseIdentifier: DetailRouteSubwayCell.id)
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, item in
            guard
                let self = self,
                sectionIndex < self.dataSource.snapshot().sectionIdentifiers.count,
                let item = self.dataSource.snapshot()
                    .itemIdentifiers(inSection: self.dataSource.snapshot().sectionIdentifiers[sectionIndex])
                    .first
            else {
                return self?.defaultSectionLayout()
            }
            
            let section = self.layout(for: item.type)
            return section
        }
    }
    
    private func defaultSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(80))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    private func layout(for type: DetailRouteInfoLayoutType) -> NSCollectionLayoutSection {
        let height: CGFloat
        switch type {
        case .start: height = 58
        case .summary: height = 120
        case .transport(let transportMode):
            switch transportMode {
            case .walk: height = 74
            case .bus: height = 175
            case .subway: height = 154
            case .unknown: height = 38
            }
        case .end: height = 58
        }
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(height))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(height))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, LegTrafficUIInfo>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item.type {
            case .summary:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetailRouteSummaryCell.id, for: indexPath) as! DetailRouteSummaryCell
                cell.configure(infos: item.routeInfos)
                return cell
            case .start:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetailRouteStartCell.id, for: indexPath) as! DetailRouteStartCell
                cell.configure(address: self.startAddress, info: item.info)
                return cell
            case .end:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetailRouteEndCell.id, for: indexPath) as! DetailRouteEndCell
                cell.configure(info: item.info)
                return cell
            case .transport(let mode):
                switch mode {
                case .walk:
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: DetailRouteWalkCell.id,
                        for: indexPath
                    ) as! DetailRouteWalkCell
                    cell.configure(info: item.info)
                    return cell
                    
                case .bus:
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: DetailRouteBusCell.id,
                        for: indexPath
                    ) as! DetailRouteBusCell
                    cell.didTapSummary = { [weak self] in
                        self?.applySnapshot()
                    }
                    cell.getNewBusRealTime = { [weak self] in
                        self?.getNewBusRealTime?()
                    }
                    cell.didTapDetail = { [weak self] in
                        let stations = (item.info?.passStopList ?? []).map {
                            PassStations(index: $0.index, stationName: $0.stationName, lat: $0.lat, lon: $0.lon)
                        }
                        let first = item.info?.passStopList?.first
                        let lat = first?.lat.flatMap { Double($0) }
                        let lon = first?.lon.flatMap { Double($0) }
                        
                        let start = AddressInfo(
                            name: first?.stationName,
                            lat: lat,
                            lon: lon
                        )
                        
                        let info = BusDetailInfo(
                            routeName: item.info?.route,
                            start: start,
                            passStations: stations,
                            targetBusStation: item.info?.targetBusStation
                        )
                        self?.onBusDetail?(info)
                    }
                    cell.configure(info: item.info)
                    cell.setupBusRealTimeInfo(busInfo: self.busRealTimeInfo)
                    return cell
                    
                case .subway:
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: DetailRouteSubwayCell.id,
                        for: indexPath
                    ) as! DetailRouteSubwayCell
                    cell.didTapSummary = { [weak self] in
                        self?.applySnapshot()
                    }
                    cell.configure(info: item.info)
                    return cell
                    
                default:
                    return nil
                }
            }
        }
    }
}

// MARK: - Gesture
extension DetailRouteInfoBottomView {
    private func setupPanGesture() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        let translation = recognizer.translation(in: superview)
        
        switch recognizer.state {
        case .changed:
            let newY = max(parentViewHeight - expandedHeight,
                           min(self.frame.origin.y + translation.y, parentViewHeight - collapsedHeight))
            self.frame.origin.y = newY
            recognizer.setTranslation(.zero, in: superview)
            
        case .ended:
            let velocity = recognizer.velocity(in: superview).y
            let shouldExpand = velocity < 0
            animateTransition(shouldExpand: shouldExpand)
            
        default:
            break
        }
    }
}

// MARK: Animation
extension DetailRouteInfoBottomView {
    private func animateTransition(shouldExpand: Bool) {
        guard let superview = self.superview else { return }
        
        let targetHeight = shouldExpand ? expandedHeight : collapsedHeight
        
        self.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(targetHeight)
        }
        
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 1.0,
                       options: [.curveEaseInOut],
                       animations: {
            superview.layoutIfNeeded()
        }, completion: { _ in
            self.currentState = shouldExpand ? .expanded : .collapsed
        })
    }
}
