//
//  DetailRouteInfoBottomView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import UIKit
import PanModal

final class DetailRouteInfoBottomView: UIView {
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var currentState: SheetState = .collapsed
    
    private let handleView: UIView = UIView()
    private let totalTimeLabel: UILabel = UILabel()
    private let startEndTimeLabel: UILabel = UILabel()
    private let progressView: DetailRouteProgressView = DetailRouteProgressView()
    private let dividerView: UIView = UIView()
    
    enum SheetState {
        case expanded
        case collapsed
    }
    
    enum Section {
        
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupPanGesture()
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupPanGesture()
        setupAutoLayout()
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

extension DetailRouteInfoBottomView {
    
}

class MyCollectionViewController: UIViewController {
    enum Section: Int, CaseIterable {
        case itemASection
        case itemBSection
    }

    // 다양한 아이템을 담을 수 있는 enum
    enum ItemType: Hashable {
        case itemA(ItemA)
        case itemB(ItemB)
    }

    struct ItemA: Hashable {
        let identifier = UUID()
        let title: String
    }

    struct ItemB: Hashable {
        let identifier = UUID()
        let description: String
    }

    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, ItemType>!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureDataSource()
        applySnapshot()
    }

    // MARK: - Compositional Layout
    private func makeCompositionalLayout() -> UICollectionViewLayout {
        // sectionIndex로 분기 (현재 스냅샷 순서가 [A, B]이므로 0=A, 1=B)
        return UICollectionViewCompositionalLayout { sectionIndex, environment in
            guard let sectionKind = Section(rawValue: sectionIndex) else { return nil }

            switch sectionKind {
            case .itemASection:
                // 1열 리스트
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(56)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(56)
                )
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 8
                section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
                return section

            case .itemBSection:
                // 가로 캐러셀 (카드형, 가운데 정렬 페이징)
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.8),
                    heightDimension: .absolute(140)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPagingCentered
                section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 20, trailing: 16)
                return section
            }
        }
    }

    // MARK: - UI / DataSource
    func configureCollectionView() {
        let layout = makeCompositionalLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
    }

    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, ItemType>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
            cell.layer.cornerRadius = 10
            cell.layer.masksToBounds = true

            var content = UIListContentConfiguration.cell()
            content.textProperties.numberOfLines = 1

            switch item {
            case .itemA(let itemA):
                cell.contentView.backgroundColor = .secondarySystemBackground
                content.text = itemA.title
                content.secondaryText = "A 섹션"
            case .itemB(let itemB):
                cell.contentView.backgroundColor = .tertiarySystemBackground
                content.text = itemB.description
                content.secondaryText = "B 섹션"
            }
            cell.contentConfiguration = content
            return cell
        }
    }

    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ItemType>()

        // Section for ItemA
        let itemsA: [ItemType] = [
            .itemA(ItemA(title: "Item A1")),
            .itemA(ItemA(title: "Item A2")),
            .itemA(ItemA(title: "Item A3")),
            .itemA(ItemA(title: "Item A4"))
        ]
        snapshot.appendSections([.itemASection])
        snapshot.appendItems(itemsA, toSection: .itemASection)

        // Section for ItemB
        let itemsB: [ItemType] = [
            .itemB(ItemB(description: "Description B1")),
            .itemB(ItemB(description: "Description B2")),
            .itemB(ItemB(description: "Description B3")),
            .itemB(ItemB(description: "Description B4"))
        ]
        snapshot.appendSections([.itemBSection])
        snapshot.appendItems(itemsB, toSection: .itemBSection)

        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
