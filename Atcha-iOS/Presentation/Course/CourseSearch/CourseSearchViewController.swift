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
        bind()
        setupAutoLayout()
        viewModel.startCourseStream()
    }
    
    // MARK: ViewModel 바인딩
    private func bind() {
        // 1. 로딩 상태에 따라 로딩뷰 제어
        viewModel.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                
                if isLoading {
                    self.showLoading()
                    self.noSearchStack.isHidden = true
                } else {
                    self.hideLoading()
                }
            }
            .store(in: &cancellables)
        
        // 2. 서버 에러 시 메시지 표시
        viewModel.$isServerError
            .combineLatest(viewModel.$isLoading)
            .receive(on: RunLoop.main)
            .sink { [weak self] (isError, isLoading) in
                guard let self = self else { return }

                if isError && !isLoading {
                    if viewModel.isBlackoutNow() {
                        self.noSearchLabel.attributedText = AtchaFont.B4_R_15("24:00 - 05:00\n막차 검색을 할 수 없어요", color: AtchaColor.gray400, alignment: .center)
                        self.noSearchLabel.numberOfLines = 0
                        self.noSearchStack.isHidden = false
                    } else {
                        self.noSearchLabel.attributedText = AtchaFont.B4_R_15("검색 가능한 막차가 없습니다.", color: AtchaColor.gray400)
                        self.noSearchStack.isHidden = false
                    }
                }
            }
            .store(in: &cancellables)
        
        // 3. 코스 데이터 변경 시 처리
        viewModel.$courses
            .receive(on: RunLoop.main)
            .sink { [weak self] courses in
                guard let self = self else { return }
                
                self.applySnapshot(courses: courses)
                
                if !self.viewModel.isLoading {
                    guard !self.viewModel.isServerError else { return }
                    if courses.isEmpty {
                        self.noSearchLabel.attributedText = AtchaFont.B4_R_15("검색 가능한 막차가 없습니다.", color: AtchaColor.gray400)
                        self.noSearchStack.isHidden = false
                    } else {
                        self.noSearchStack.isHidden = true
                    }
                }
            }
            .store(in: &cancellables)
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
    }
    
    // MARK: - 경로탐색 AutoLayout
    private func setupAutoLayout() {
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
        
        cell.onGetAlarmTapped = { [weak self] in
            guard let self else { return }
            let course = model.course
            let r = self.viewModel.ranks(for: course)
            
            let pathInfo: [LegPathInfo] = model.course.toLegPathInfos()
            let trafficInfo: [LegTrafficInfo] = model.course.toLegTrafficInfos()
            let busInfo: [BusDetailInfo] = model.course.toBusInfos()
            
            let alarmRequest = AlarmRequest(lastRouteId: model.course.routeId)
            let alarmTapped = (viewModel.startAddress, LegInfo(pathInfo: pathInfo, trafficInfo: trafficInfo, busInfo: busInfo))
            
            let busLegs = trafficInfo.filter { $0.mode == .bus }
            let busCount = busLegs.count
            let hasSubway = trafficInfo.contains { $0.mode == .subway }
            let hasLongWaitBus = busLegs.contains { ($0.targetBusTerm ?? 0) >= 40 }

            let isException = (busCount == 1) && (hasSubway == false)

            let shouldShowPopup = hasLongWaitBus && !isException

            let isAlarmRegistered = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue) ?? false
            
            if shouldShowPopup {
                showCoursePopup(alarmRequest, alarmTapped, r)
            } else {
                viewModel.alarmRegister(alarmRequest)
                viewModel.getAlarmTapped?(alarmTapped.0, alarmTapped.1)
                
                let second = AmplitudeManager.shared.timerEndSeconds("notification_registration_duration")
                let userID = UserDefaultsWrapper.shared.double(forKey: UserDefaultsWrapper.Key.userId.rawValue) ?? 0.0
                
                AmplitudeManager.shared.track(
                    AmplitudeEvent.notification_registration_duration.rawValue ,
                    [
                        "screen_name": "coursesearch",
                        "duration": second,
                        "USER_ID": String(userID),
                    ]
                )
                
                AmplitudeManager.shared.track(
                    AmplitudeEvent.alarm_registered.rawValue,
                    [
                        "later_departure_time_rank": r.laterDepartureTimeRank,
                        "minimal_walk_rank":        r.minimalWalkRank,
                        "minimal_total_time_rank":  r.minimalTotalTimeRank,
                        "transfer_count":           r.transferCount
                    ]
                )
                
                print(r)
                navigationController?.popToRootViewController(animated: true)
            }
        }
        
        // 버튼 탭 시 경로ID와 함께 상세 화면으로 이동
        cell.onDetailTapped = { [weak self] in
            guard let self else { return }
            let pathInfo: [LegPathInfo] = model.course.toLegPathInfos()
            let tafficInfo: [LegTrafficInfo] = model.course.toLegTrafficInfos()
            let busInfo: [BusDetailInfo] = model.course.toBusInfos()
            viewModel.getDetailTapped?(viewModel.startAddress, LegInfo(pathInfo: pathInfo, trafficInfo: tafficInfo, busInfo: busInfo))
            viewModel.saveStartInfo("")
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
        noSearchLabel.attributedText = AtchaFont.B4_R_15("앗! 시간이 늦어서 더이상 막차가 없어요.", color: AtchaColor.gray400)
        
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

extension CourseSearchViewController {
    
    private func showCoursePopup(_ alarmRequest: AlarmRequest, _ alarmTapped: (String, LegInfo), _ rank: RouteRanks) {
        let popupVM = AtchaPopupViewModel(info: .course)
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.confirmButton.addAction(UIAction { [weak popupVC] _ in
            popupVC?.dismiss(animated: true)
            
            self.viewModel.alarmRegister(alarmRequest)
            self.viewModel.getAlarmTapped?(alarmTapped.0, alarmTapped.1)
            
            let second = AmplitudeManager.shared.timerEndSeconds("notification_registration_duration")
            let userID = UserDefaultsWrapper.shared.double(forKey: UserDefaultsWrapper.Key.userId.rawValue) ?? 0.0
            
            AmplitudeManager.shared.track(
                AmplitudeEvent.notification_registration_duration.rawValue ,
                [
                    "screen_name": "coursesearch",
                    "duration": second
                ]
            )
            
            AmplitudeManager.shared.track(
                AmplitudeEvent.alarm_registered.rawValue,
                [
                    "later_departure_time_rank": rank.laterDepartureTimeRank,
                    "minimal_walk_rank":        rank.minimalWalkRank,
                    "minimal_total_time_rank":  rank.minimalTotalTimeRank,
                    "transfer_count":           rank.transferCount
                ]
            )
            
            self.navigationController?.popToRootViewController(animated: true)
            
        }, for: .touchUpInside)
        
        popupVC.cancelButton.addAction(UIAction { [weak self, weak popupVC] _ in
            guard let _ = self else { return }
            popupVC?.dismiss(animated: false)
            
        }, for: .touchUpInside)
        
        popupVC.modalPresentationStyle = .overFullScreen
        present(popupVC, animated: false)
    }
    
    private func showRe_RegisterPopup(_ alarmRequest: AlarmRequest, _ alarmTapped: (String, LegInfo)) {
        let popupVM = AtchaPopupViewModel(info: .re_register)
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.confirmButton.addAction(UIAction { [weak popupVC] _ in
            popupVC?.dismiss(animated: true)
            
            self.viewModel.alarmRegister(alarmRequest)
            self.viewModel.getAlarmTapped?(alarmTapped.0, alarmTapped.1)
            self.navigationController?.popToRootViewController(animated: true)
            
        }, for: .touchUpInside)
        
        popupVC.cancelButton.addAction(UIAction { [weak self, weak popupVC] _ in
            guard let _ = self else { return }
            popupVC?.dismiss(animated: false)
            
        }, for: .touchUpInside)
        
        popupVC.modalPresentationStyle = .overFullScreen
        present(popupVC, animated: false)
    }
}
