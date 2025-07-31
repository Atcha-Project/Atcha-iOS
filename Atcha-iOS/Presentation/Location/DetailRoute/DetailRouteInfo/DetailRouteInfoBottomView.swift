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
        return parentViewHeight * 0.45
    }
    
    private var expandedHeight: CGFloat {
        return parentViewHeight * 0.78
    }
    
    private let routerInfo: [LegTrafficInfo] = []
    private var dataSource: UICollectionViewDiffableDataSource<Section, LegTrafficInfo>!
    private var collectionView: UICollectionView!
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var currentState: SheetState = .collapsed
    
    private let handleView: UIView = UIView()
    private let totalTimeLabel: UILabel = UILabel()
    private let startEndTimeLabel: UILabel = UILabel()
    private let progressView: DetailRouteProgressView = DetailRouteProgressView()
    private let dividerView: UIView = UIView()
    
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
        
        totalTimeLabel.attributedText = AtchaFont.H1_B_26("1시간 24분") // 폰트 변경해야함
        startEndTimeLabel.attributedText = AtchaFont.B7_M_13("22:32 ~ 23:42", color: .gray400)
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
        print("infos: \(infos)")
        
        guard collectionView.dataSource != nil else {
            assertionFailure("💥 collectionView.dataSource가 설정되기 전에 데이터 apply 시도됨")
            return
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, LegTrafficInfo>()
        for info in infos {
            let section = Section.item(info.id)
            snapshot.appendSections([section])
            snapshot.appendItems([info], toSection: section)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
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
        
        collectionView.register(DetailRouteStartCell.self, forCellWithReuseIdentifier: "DetailRouteStartCell")
        collectionView.register(DetailRouteWalkCell.self, forCellWithReuseIdentifier: "DetailRouteWalkCell")
        collectionView.register(DetailRouteBusCell.self, forCellWithReuseIdentifier: "DetailRouteBusCell")
        collectionView.register(DetailRouteSubwayCell.self, forCellWithReuseIdentifier: "DetailRouteSubwayCell")
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard
                let self = self,
                sectionIndex < self.dataSource.snapshot().sectionIdentifiers.count,
                let item = self.dataSource.snapshot()
                    .itemIdentifiers(inSection: self.dataSource.snapshot().sectionIdentifiers[sectionIndex])
                    .first
            else {
                return self?.defaultSectionLayout() ?? NSCollectionLayoutSection(group: NSCollectionLayoutGroup.vertical(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .absolute(80)),
                    subitems: []
                ))
            }
            return self.layout(for: item.mode ?? .bus)
        }
    }
    
    private func defaultSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(80))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return section
    }

    private func layout(for type: TransportMode) -> NSCollectionLayoutSection {
        let height: CGFloat

        switch type {
        case .walk:
            height = 70
        case .bus:
            height = 170
        case .subway:
            height = 160
        default:
            height = 38
        }

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(height))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(height))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        return section
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, LegTrafficInfo>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item.mode {
            case .walk:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetailRouteWalkCell.id, for: indexPath) as! DetailRouteWalkCell
                cell.configure(info: item)
                return cell
            case .bus:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetailRouteBusCell.id, for: indexPath) as! DetailRouteBusCell
                cell.configure(info: item)
                return cell
            case .subway:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetailRouteSubwayCell.id, for: indexPath) as! DetailRouteSubwayCell
                cell.configure(info: item)
                return cell
            default:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetailRouteStartCell.id, for: indexPath) as! DetailRouteStartCell
                cell.configure(info: item)
                return cell
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
    
    private func animateTransition(shouldExpand: Bool) {
        guard let _ = self.superview else { return }
        let targetY = shouldExpand ? (parentViewHeight - expandedHeight) : (parentViewHeight - collapsedHeight)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: [.curveEaseInOut], animations: {
            self.frame.origin.y = targetY
        }, completion: { _ in
            self.currentState = shouldExpand ? .expanded : .collapsed
        })
    }
}
