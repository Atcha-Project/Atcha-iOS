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
    private let totalTimeLabel: UILabel = UILabel()
    private let startEndTimeLabel: UILabel = UILabel()
    private let progressView: DetailRouteProgressView = DetailRouteProgressView()
    private let dividerView: UIView = UIView()
    
    private var startAddress: String = ""
    private var busRealTimeInfo: [BusRealTimeInfo] = []
    var onBusDetail: ((BusDetailInfo) -> Void)?
    
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
        addSubViews(handleView,
                    totalTimeLabel,
                    startEndTimeLabel,
                    progressView,
                    dividerView)
        
        backgroundColor = .gray950
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        handleView.backgroundColor = .gray700
        dividerView.backgroundColor = .opacity100
    }
    
    private func setupAutoLayout() {
        handleView.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(4)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(12)
        }
        
        totalTimeLabel.snp.makeConstraints { make in
            make.height.equalTo(34)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.top.equalTo(handleView.snp.bottom).offset(12)
        }
        
        startEndTimeLabel.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.top.equalTo(totalTimeLabel.snp.bottom).offset(6)
        }
        
        progressView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(16)
            make.top.equalTo(startEndTimeLabel.snp.bottom).offset(16)
        }
        
        dividerView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(progressView.snp.bottom).offset(16)
        }
    }
    
    func setupRouteInfo(_ infos: [LegTrafficInfo]) {
        totalTimeLabel.attributedText = AtchaFont.H1_B_26(infos.first?.totalTime ?? "")
        startEndTimeLabel.attributedText = AtchaFont.B7_M_13(infos.first?.timeText ?? "", color: .gray400)
        progressView.configure(infos: infos)
        
        snapshot = NSDiffableDataSourceSnapshot<Section, LegTrafficUIInfo>()
        
        for (index, info) in infos.enumerated() {
            let section = Section.item(info.id)
            snapshot.appendSections([section])
            
            var items: [LegTrafficUIInfo] = []
            
            // ✅ 시작 셀은 첫 번째 info에만
            if index == 0 {
                items.append(LegTrafficUIInfo(type: .start, info: info))
            }
            
            // ✅ 이동 수단 셀 추가
            switch info.mode {
            case .walk:
                items.append(LegTrafficUIInfo(type: .transport(.walk), info: info))
            case .bus:
                items.append(LegTrafficUIInfo(type: .transport(.bus), info: info))
            case .subway:
                items.append(LegTrafficUIInfo(type: .transport(.subway), info: info))
            default:
                items.append(LegTrafficUIInfo(type: .transport(.unknown), info: info))
            }
            
            // ✅ 마지막 info에만 종료 셀 추가
            if index == infos.count - 1 {
                items.append(LegTrafficUIInfo(type: .end, info: info))
            }
            
            snapshot.appendItems(items, toSection: section)
        }
        
        applySnapshot()
    }
    
    func setupBusTimerLabel(_ time: [BusRealTimeInfo]) {
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
            $0.top.equalTo(dividerView.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .gray950
        collectionView.register(DetailRouteStartCell.self, forCellWithReuseIdentifier: DetailRouteStartCell.id)
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
        case .start: height = 40
            //        case .summary: height = 120
        case .transport(let transportMode):
            switch transportMode {
            case .walk: height = 70
            case .bus: height = 175
            case .subway: height = 154
            case .unknown: height = 38
            }
        case .end:
            height = 40
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
                //            case .summary:
                //
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
                    cell.didTapDetail = { [weak self] in
                        let stations = (item.info.passStopList ?? []).map {
                            PassStations(index: $0.index, stationName: $0.stationName, lat: $0.lat, lon: $0.lon)
                        }
                        let first = item.info.passStopList?.first
                        let lat = first?.lat.flatMap { Double($0) }
                        let lon = first?.lon.flatMap { Double($0) }
                        
                        let start = AddressInfo(
                            name: first?.stationName,
                            lat: lat,
                            lon: lon
                        )
                        
                        let info = BusDetailInfo(
                            routeName: item.info.route,
                            start: start,
                            passStations: stations,
                            targetBusStation: item.info.targetBusStation
                        )
                        self?.onBusDetail?(info)
                    }
                    cell.configure(info: item.info, busInfo: self.busRealTimeInfo)
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
