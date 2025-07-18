//
//  CourseSearchViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/3/25.
//

import UIKit
import SnapKit
import Combine

final class CourseSearchViewController: BaseViewController<CourseSearchViewModel> {
    
    private lazy var topNavigationBar: TitleNavigationBar = AtchaNavigationBar.title("") { [weak self] in
        self?.navigationController?.popViewController(animated: true)
    } onClose: {
        [weak self] in
        self?.navigationController?.popToRootViewController(animated: true)
    }
    private let courseView: UIView = UIView()
    private let routeLabelStack: UIStackView = UIStackView()
    private let departLabel: UILabel = UILabel()
    private let arriveLabel: UILabel = UILabel()
    private let arrowImageView: UIImageView = UIImageView()
    private let tabItems = ["전체", "버스", "지하철"]
    private var selectedIndex = 0
    private lazy var tabCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = AtchaColor.gray950
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CourseTabCell.self, forCellWithReuseIdentifier: "CourseTabCell")
        
        return collectionView
    }()
    private lazy var courseCollectionView: UICollectionView = {
        let layout = layout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.register(CourseCell.self, forCellWithReuseIdentifier: CourseCell.reusableId)
        return cv
    }()
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, CourseUIModel>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, CourseUIModel>
    private lazy var dataSource: DataSource = setDataSource()
    private var currentSection: [Section] {
        dataSource.snapshot().sectionIdentifiers as [Section]
    }
    private enum Section {
        case courseList
    }
    private let noSearchStack: UIStackView = UIStackView()
    private let noSearchImageView: UIImageView = UIImageView()
    private let noSearchLabel: UILabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        NoSearchCourseUI()
        noSearchStack.isHidden = true
        bind()
        viewModel.courseSearch()
    }
    
    // MARK: - 경로탐색 UI
    private func setupUI() {
        view.backgroundColor = AtchaColor.gray950
        
        courseView.layer.cornerRadius = 12
        courseView.backgroundColor = AtchaColor.gray930
        
        departLabel.attributedText = AtchaFont.B4_R_15(viewModel.startAddress, color: AtchaColor.white)
        arriveLabel.attributedText = AtchaFont.B4_R_15("우리집", color: AtchaColor.white)
        
        arrowImageView.image = .arrow
        arrowImageView.tintColor = AtchaColor.white
        arrowImageView.contentMode = .scaleAspectFit
        
        routeLabelStack.addArrangedSubview(departLabel)
        routeLabelStack.addArrangedSubview(arrowImageView)
        routeLabelStack.addArrangedSubview(arriveLabel)
        routeLabelStack.axis = .horizontal
        routeLabelStack.spacing = 8
        
        courseView.addSubview(routeLabelStack)
        
        view.addSubViews(topNavigationBar, courseView, tabCollectionView, courseCollectionView)
        
        topNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.trailing.leading.equalToSuperview()
        }
        
        routeLabelStack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(courseView.snp.leading).offset(16)
        }
        
        courseView.snp.makeConstraints { make in
            make.top.equalTo(topNavigationBar.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        
        tabCollectionView.snp.makeConstraints { make in
            make.top.equalTo(courseView.snp.bottom).offset(10)
            make.trailing.leading.equalToSuperview()
            make.height.equalTo(40)
        }
        
        courseCollectionView.snp.makeConstraints { make in
            make.top.equalTo(tabCollectionView.snp.bottom)
            make.trailing.leading.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: ViewModel 바인딩
    private func bind() {
        viewModel.$courses
            .receive(on: RunLoop.main)
            .sink { [weak self] courses in
                self?.applySnapshot(courses: courses)
                
                if courses.isEmpty {
                    self?.noSearchStack.isHidden = false
                } else {
                    self?.noSearchStack.isHidden = true
                }
                
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Course CollectionView DataSource & Cell 바인딩
    private func setDataSource() -> DataSource {
        let dataSource: DataSource = UICollectionViewDiffableDataSource(collectionView: courseCollectionView)
        { [weak self] collectionView, indexPath, course in
            switch self?.currentSection[indexPath.section] {
            case .courseList:
                return self?.courseCell(collectionView, indexPath, course)
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
            case .courseList:
                return CourseCell.courseLayout()
            case .none:
                return nil
            }
        }
    }
    
    // MARK: - Course CollectionView Cell 설정
    private func courseCell(_ collectionView: UICollectionView, _ indexPath: IndexPath, _ model: CourseUIModel) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CourseCell.reusableId, for: indexPath) as? CourseCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: model)
        
        // 버튼 탭 시 경로ID와 함께 상세 화면으로 이동
        cell.onDetailTapped = { 
            print(model.course.routeId ?? "경로 ID 없음")
        }
        
        // 버튼 탭 시 확장/축소 상태 변경 핸들러 연결
        cell.onToggleExpanded = { [weak self] in
            self?.viewModel.toggleExpanded(for: model)
        }
        
        return cell
    }
    
    // MARK: - Course Snapshot 갱신
    private func applySnapshot(courses: [CourseUIModel]) {
        var snapshot = Snapshot()
        
        snapshot.appendSections([.courseList])
        if !courses.isEmpty {
            snapshot.appendItems(courses, toSection: .courseList)
        }
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - 검색 결과 없을 경우 UI
    private func NoSearchCourseUI() {
        noSearchImageView.image = UIImage.atchaGray
        noSearchImageView.contentMode = .scaleAspectFit
        noSearchLabel.attributedText = AtchaFont.B4_R_15("검색 가능한 막차 정보가 없습니다.", color: AtchaColor.gray400)
        
        noSearchStack.addArrangedSubview(noSearchImageView)
        noSearchStack.addArrangedSubview(noSearchLabel)
        noSearchStack.axis = .vertical
        noSearchStack.spacing = 16
        
        view.addSubview(noSearchStack)
        
        noSearchStack.snp.makeConstraints { make in
            make.center.equalTo(courseCollectionView)
        }
    }
}

extension CourseSearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CourseTabCell", for: indexPath) as? CourseTabCell else {
            return UICollectionViewCell()
        }
        let title = tabItems[indexPath.item]
        let isSelected = (indexPath.item == selectedIndex)
        cell.configure(title: title, selected: isSelected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == tabCollectionView {
            selectedIndex = indexPath.item
            viewModel.fetchCourses(for: selectedIndex)
            collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / CGFloat(tabItems.count)
        return CGSize(width: width, height: 40)
    }
}

