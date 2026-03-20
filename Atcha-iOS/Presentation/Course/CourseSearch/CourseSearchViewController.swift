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
    
    private lazy var topNavigationBar: CloseOnlyNavigationBar = AtchaNavigationBar.CloseOnly(onClose: {
        [weak self] in
        self?.navigateBackByContext()
    })
    private let courseView: UIView = UIView()
    private let routeLabelStack: UIStackView = UIStackView()
    private let departLabel: UILabel = UILabel()
    private let arriveLabel: UILabel = UILabel()
    private let arrowImageView: UIImageView = UIImageView()
    private let tabItems = ["전체", "버스", "지하철"]
    private var selectedIndex = 0
    private let courseSortView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        
        return stackView
    }()
    private let courseSortLabel: UILabel = UILabel()
    private let courseSortImageView: UIImageView = UIImageView()
    private lazy var tabCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 4
        
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
        cv.backgroundColor = AtchaColor.black
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
    private var previousLatestId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupGesture()
        NoSearchCourseUI()
        bind()
        setupAutoLayout()
        viewModel.updateTabIndex(0)
        viewModel.startCourseStream()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        amp_track(.course_search_view)
        AmplitudeManager.shared.timerStart("alarm_dwell")
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
                    self.courseCollectionView.backgroundColor = AtchaColor.black
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
                        self.courseCollectionView.backgroundColor = AtchaColor.gray950
                    } else {
                        self.noSearchLabel.attributedText = AtchaFont.B4_R_15("검색 가능한 막차가 없습니다.", color: AtchaColor.gray400)
                        self.noSearchStack.isHidden = false
                        self.courseCollectionView.backgroundColor = AtchaColor.gray950
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
            }
            .store(in: &cancellables)
    }
    
    private func navigateBackByContext() {
        switch viewModel.context {
        case .beforeRegister:
            // 등록 전: 홈(지도)으로 완전히 나감
            self.navigationController?.popToRootViewController(animated: true)
        case .afterReigster: // 오타 주의: afterReigster (i 누락된 유저님 코드 기준)
            // 락스크린에서 옴: 바로 아래에 깔린 DetailRoute로 돌아감
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - 경로탐색 UI
    private func setupUI() {
        view.backgroundColor = AtchaColor.gray950
        
        noSearchStack.isHidden = true
        courseCollectionView.backgroundColor = AtchaColor.black
        
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
        
        courseSortLabel.attributedText = AtchaFont.B7_M_13("늦은 출발순", color: AtchaColor.white)
        courseSortImageView.image = .chevronDown
        courseSortImageView.tintColor = AtchaColor.white
        courseSortImageView.contentMode = .scaleAspectFit
        
        courseSortView.addArrangedSubview(courseSortLabel)
        //        courseSortView.addArrangedSubview(courseSortImageView)
        
        view.addSubViews(topNavigationBar, courseView, tabCollectionView, courseSortView, courseCollectionView)
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
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(52)
            make.height.equalTo(44)
        }
        
        tabCollectionView.snp.makeConstraints { make in
            make.top.equalTo(courseView.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
        
        courseSortImageView.snp.makeConstraints { make in
            make.size.equalTo(8.51)
        }
        
        courseSortView.snp.makeConstraints { make in
            make.bottom.equalTo(tabCollectionView.snp.bottom).inset(10)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(16)
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
        
        let visibleCourses = viewModel.courses
        let latestId = viewModel.latestDepartureCourseId(in: visibleCourses)
        let isLast = (model.id == latestId)
        cell.configure(with: model, isLast: isLast)
        
        cell.onGetAlarmTapped = { [weak self] in
            guard let self else { return }
            
            let hasConfigured = UserDefaults.standard.bool(forKey: "hasSeenAlarmSettingsSheet")
            
            if !hasConfigured {
                // 처음이라면 설정 시트를 먼저 띄움
                self.presentPushAlarmSheet { [weak self] in
                    UserDefaults.standard.set(true, forKey: "hasSeenAlarmSettingsSheet")
                    self?.handleAlarmPermissionAndRegistration(for: model)
                }
            } else {
                // 이미 설정했다면 바로 권한 체크 및 등록 진행
                self.handleAlarmPermissionAndRegistration(for: model)
            }
        }
        
        // 버튼 탭 시 경로ID와 함께 상세 화면으로 이동
        cell.onDetailTapped = { [weak self] in
            guard let self else { return }
            let pathInfo: [LegPathInfo] = model.course.toLegPathInfos()
            let tafficInfo: [LegTrafficInfo] = model.course.toLegTrafficInfos()
            let busInfo: [BusDetailInfo] = model.course.toBusInfos()
            viewModel.getDetailTapped?(viewModel.startAddress, LegInfo(pathInfo: pathInfo, trafficInfo: tafficInfo, busInfo: busInfo))
            viewModel.saveStartInfo(model.course.routeId ?? "")
            amp_track(.course_detail_click)
        }
        
        return cell
    }
    
    // MARK: - Course Snapshot 갱신
    private func applySnapshot(courses: [CourseUIModel]) {
        // 1. 지금 들어온 데이터 중 1등(가장 늦은 막차)이 누구인지 확인
        let currentLatestId = viewModel.latestDepartureCourseId(in: courses)
        
        var snapshot = Snapshot()
        snapshot.appendSections([.courseList])
        snapshot.appendItems(courses, toSection: .courseList)
        
        // 2. 만약 1등이 바뀌었다면? (예: 원래 A였는데 더 늦은 B가 들어옴)
        if let lastId = previousLatestId, lastId != currentLatestId {
            
            // [중요] 모든 셀이 아니라, 딱 '이전 1등'과 '현재 1등'만 다시 그리라고 명령합니다.
            var itemsToUpdate: [CourseUIModel] = []
            
            // 이전 1등이었던 셀 (이제 배지를 떼야 함)
            if let oldItem = courses.first(where: { $0.id == lastId }) {
                itemsToUpdate.append(oldItem)
            }
            // 새로운 1등인 셀 (이제 배지를 달아야 함)
            if let newItem = courses.first(where: { $0.id == currentLatestId }) {
                itemsToUpdate.append(newItem)
            }
            
            if #available(iOS 15.0, *), !itemsToUpdate.isEmpty {
                snapshot.reconfigureItems(itemsToUpdate)
            }
        }
        
        // 3. 상태 저장 및 스냅샷 적용
        previousLatestId = currentLatestId
        
        // animatingDifferences를 true로 두면 1 ( ) 2 사이에 부드럽게 slide-in 됩니다.
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
    
    private func setupGesture() {
        courseView.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapRouteStack))
        courseView.addGestureRecognizer(tap)
    }
    
    
    @objc private func didTapRouteStack() {
        viewModel.didTapRouteLabelStack()
        
        amp_track(.course_modify_click)
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
            viewModel.updateTabIndex(selectedIndex)
            collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = 52
        return CGSize(width: width, height: 40)
    }
}

extension CourseSearchViewController {
    
    private func showCoursePopup(_ alarmRequest: AlarmRequest, _ alarmTapped: (String, LegInfo)) {
        let popupVM = AtchaPopupViewModel(info: .course)
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.confirmButton.addAction(UIAction { [weak popupVC] _ in
            popupVC?.dismiss(animated: false)
            
            self.viewModel.alarmRegister(alarmRequest)
            self.viewModel.getAlarmTapped?(alarmTapped.0, alarmTapped.1)
            UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.popRegister.rawValue)
            
            let dwellSeconds = AmplitudeManager.shared.timerEndSeconds("alarm_dwell")
            
            self.amp_track(.long_interval_alarm_register, properties: props(
                AmplitudeProperty.dwellTime(seconds: dwellSeconds)
            ))
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
            popupVC?.dismiss(animated: false)
            
            self.viewModel.alarmRegister(alarmRequest)
            self.viewModel.getAlarmTapped?(alarmTapped.0, alarmTapped.1)
            UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.popRegister.rawValue)
            
            let dwellSeconds = AmplitudeManager.shared.timerEndSeconds("alarm_dwell")
            self.amp_track(.another_alarm_register, properties: props(
                AmplitudeProperty.dwellTime(seconds: dwellSeconds)
            ))
            
            
        }, for: .touchUpInside)
        
        popupVC.cancelButton.addAction(UIAction { [weak self, weak popupVC] _ in
            guard let _ = self else { return }
            popupVC?.dismiss(animated: false)
            
        }, for: .touchUpInside)
        
        popupVC.modalPresentationStyle = .overFullScreen
        present(popupVC, animated: false)
    }
}

extension CourseSearchViewController {
    private func presentPushAlarmSheet(completion: @escaping () -> Void) {
        let sheetVM = PushAlarmSheetViewModel()
        let sheetVC = PushAlarmSheetViewController(viewModel: sheetVM)
        
        sheetVC.modalPresentationStyle = .overFullScreen
        
        sheetVC.onComplete = {
            completion()
        }
        
        sheetVC.onDismiss = {
        }
        
        present(sheetVC, animated: false)
    }
    
    /// 권한 확인 및 실제 서버 알람 등록 처리
    private func handleAlarmPermissionAndRegistration(for model: CourseUIModel) {
        self.ensureAlarmPermissionAndExecute { [weak self] in
            guard let self = self else { return }
            
            let pathInfo: [LegPathInfo] = model.course.toLegPathInfos()
            let trafficInfo: [LegTrafficInfo] = model.course.toLegTrafficInfos()
            let busInfo: [BusDetailInfo] = model.course.toBusInfos()
            
            let alarmRequest = AlarmRequest(lastRouteId: model.course.routeId)
            let alarmData = (self.viewModel.startAddress, LegInfo(pathInfo: pathInfo, trafficInfo: trafficInfo, busInfo: busInfo))
            
            // 팝업 노출 여부 결정 로직 (기존 로직 유지)
            let busLegs = trafficInfo.filter { $0.mode == .bus }
            let hasSubway = trafficInfo.contains { $0.mode == .subway }
            let hasLongWaitBus = busLegs.contains { ($0.targetBusTerm ?? 0) >= 40 }
            let isException = (busLegs.count == 1) && (hasSubway == false)
            let shouldShowPopup = hasLongWaitBus && !isException
            
            let isAlreadyRegistered = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue) ?? false
            
            if isAlreadyRegistered {
                if shouldShowPopup {
                    self.showCoursePopup(alarmRequest, alarmData)
                } else {
                    self.showRe_RegisterPopup(alarmRequest, alarmData)
                }
            } else {
                if shouldShowPopup {
                    self.showCoursePopup(alarmRequest, alarmData)
                } else {
                    // 서버에 알람 등록 실행
                    self.viewModel.alarmRegister(alarmRequest)
                    self.viewModel.getAlarmTapped?(alarmData.0, alarmData.1)
                    
                    // 앰플리튜드 트래킹 및 메인 이동
                    let dwellSeconds = AmplitudeManager.shared.timerEndSeconds("alarm_dwell")
                    
                    self.amp_track(.alarm_register, properties: props(
                        AmplitudeProperty.dwellTime(seconds: dwellSeconds)
                    ))
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
}
