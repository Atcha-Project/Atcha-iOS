//
//  CourseSearchViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/3/25.
//

import Foundation

// MARK: - 코스 셀의 UI 상태를 포함하는 모델
/// `CourseUIModel`은 코스 데이터(Course)와 UI 상태(확장 여부)를 함께 관리하기 위한 구조체입니다.
/// DiffableDataSource에서 셀 상태 변경 시 애니메이션이 정상적으로 작동하도록 `Hashable`을 커스터마이징하여
/// `isExpanded` 값이 바뀔 때도 Snapshot이 셀을 인식할 수 있도록 구성했습니다.
struct CourseUIModel: Hashable {
    let id: String
    let course: Course
    var isExpanded: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isExpanded)
    }
    
    static func == (lhs: CourseUIModel, rhs: CourseUIModel) -> Bool {
        return lhs.id == rhs.id && lhs.isExpanded == rhs.isExpanded
    }
}

struct RouteRanks {
    let laterDepartureTimeRank: Int      // 출발이 얼마나 늦은지 (늦을수록 1위)
    let minimalWalkRank: Int             // 도보가 얼마나 적은지 (적을수록 1위)
    let minimalTotalTimeRank: Int        // 총 소요시간이 얼마나 짧은지 (짧을수록 1위)
    let transferCount: Int               // 환승 횟수
}

final class CourseSearchViewModel: BaseViewModel {
    @Published var courses: [CourseUIModel] = []
    private var allCourses: [CourseUIModel] = []
    @Published var isServerError: Bool = false
    
    private let courseUseCase: CourseUseCase
    private let alarmUseCase: AlarmUseCase
    private let startLat: String
    private let startLon: String
    public private(set) var startAddress: String
    private var courseStreamTask: Task<Void, Never>?
    private(set) var currentTabIndex: Int = 0
    
    var getAlarmTapped: ((String, LegInfo) -> Void)?
    var getDetailTapped: ((String, LegInfo) -> Void)?
    
    private let kst = TimeZone(identifier: "Asia/Seoul")!
    private let cutoffHour = 3 // 새벽 3시까지 검색
    private var anchorDate: Date? // 검색 시작 시 고정
    
    init(
        courseUseCase: CourseUseCase,
        alarmUseCase: AlarmUseCase,
        startLat: String,
        startLon: String,
        startAddress: String
    ) {
        self.courseUseCase = courseUseCase
        self.alarmUseCase = alarmUseCase
        self.startLat = startLat
        self.startLon = startLon
        self.startAddress = startAddress
        super.init()
    }
    
    
    // MARK: - 탭별 코스
    func fetchCourses(for tabIndex: Int) {
        // 1) 탭별 베이스 리스트 만들기
        let base: [CourseUIModel]
        switch tabIndex {
        case 0:
            // 전체
            base = allCourses
            
        case 1:
            base = allCourses.filter { m in
                let modes = m.course.legs.compactMap { $0.mode }
                let hasBusOnly = modes.contains(.bus) && !modes.contains(.subway)
                return hasBusOnly
            }
            
        case 2:
            base = allCourses.filter { m in
                let modes = m.course.legs.compactMap { $0.mode }
                let hasSubwayOnly = modes.contains(.subway) && !modes.contains(.bus)
                return hasSubwayOnly
            }
            
        default:
            base = []
        }
        
        let sorted = base.sorted(by: isLess(_:_:))
        
        if courses != sorted {
            self.courses = sorted
        }
    }
    
    func updateTabIndex(_ index: Int) {
        currentTabIndex = index
        fetchCourses(for: index)
    }
    
    // MARK: - 코스 검색
    func courseSearch() {
        Task {
            do {
                let userDefaults = UserDefaultsWrapper.shared
                let endLat = userDefaults.string(forKey: UserDefaultsWrapper.Key.homeLat.rawValue) ?? "37.554722"
                let endLon = userDefaults.string(forKey: UserDefaultsWrapper.Key.homeLon.rawValue) ?? "126.970833"
                
                let request = CourseSearchRequest(startLat: startLat, startLon: startLon, endLat: endLat, endLon: endLon)
                
                let response = try await courseUseCase.courseSearch(request)
                
                let uiModels = response.map {
                    CourseUIModel(id: $0.routeId ?? UUID().uuidString, course: $0, isExpanded: false)
                }
                
                self.allCourses = uiModels
                self.fetchCourses(for: self.currentTabIndex)
            } catch {
                print("탭별 코스 가져오기 실패: \(error)")
                self.isServerError = true
                self.courses = []
            }
        }
    }
    
    // MARK: - 코스 검색 스트리밍용
    func startCourseStream() {
        
        if isBlackoutNow() {
            setLoading(false)
            isServerError = true
            courses = []
            return
        }
        
        courseStreamTask?.cancel()
        setLoading(true)
        anchorDate = Date()
        
        courseStreamTask = Task {
            do {
                let userDefaults = UserDefaultsWrapper.shared
                let endLat = userDefaults.string(forKey: UserDefaultsWrapper.Key.homeLat.rawValue) ?? "37.554722"
                let endLon = userDefaults.string(forKey: UserDefaultsWrapper.Key.homeLon.rawValue) ?? "126.970833"
                
                let request = CourseSearchRequest(
                    startLat: startLat,
                    startLon: startLon,
                    endLat: endLat,
                    endLon: endLon
                )
                
                var hasReceived = false
                
                for try await course in courseUseCase.observeCourseStream(request) {
                    setLoading(false)
                    hasReceived = true
                    
                    let uiModel = CourseUIModel(id: course.routeId ?? UUID().uuidString,
                                                course: course, isExpanded: false)
                    if !self.allCourses.contains(where: { $0.id == uiModel.id }) {
                        self.allCourses.append(uiModel)
                        self.allCourses.sort(by: isLess(_:_:))
                        self.fetchCourses(for: self.currentTabIndex)
                    }
                }
                
                if !hasReceived {
                    print("스트림에서 아무 응답도 수신되지 않음")
                    self.setLoading(false)
                    self.isServerError = true
                }
                
            } catch {
                print("스트림 오류 발생: \(error.localizedDescription)")
                self.setLoading(false)
                self.isServerError = true
                self.courses = []
            }
        }
    }
    
    // MARK: - 알림 등록
    func alarmRegister(_ request: AlarmRequest) {
        Task {
            do {
                let _ = try await alarmUseCase.alarmRegister(request)
                saveStartInfo(request.lastRouteId)
            } catch {
                print("알람 등록 실패: \(error)")
            }
        }
    }
    
    func saveStartInfo(_ lastRouteId: String?) {
        let wrapper = UserDefaultsWrapper.shared
        wrapper.set(startLat, forKey: UserDefaultsWrapper.Key.startLat.rawValue)
        wrapper.set(startLon, forKey: UserDefaultsWrapper.Key.startLon.rawValue)
        wrapper.set(startAddress, forKey: UserDefaultsWrapper.Key.startAddress.rawValue)
        wrapper.set(lastRouteId, forKey: UserDefaultsWrapper.Key.lastRouteId.rawValue)
    }
    
    func stopCourseStream() {
        courseStreamTask?.cancel()
        courseStreamTask = nil
    }
    
    deinit {
        stopCourseStream()
    }
    
    // MARK: UI 확장을 위한 토글 함수
    func toggleExpanded(for model: CourseUIModel) {
        guard let index = courses.firstIndex(of: model) else { return }
        
        var newModel = courses[index]
        newModel.isExpanded.toggle()
        courses[index] = newModel
    }
    
    
    // MARK: - 서버 ISO 문자열 파싱
    private func parseServerDate(_ iso: String) -> Date? {
        // 1) 타임존 명시(Z 또는 +09:00 등)된 경우: ISO8601로
        let tzRegex = #"[+-]\d{2}:\d{2}"#
        let hasTZ = iso.contains("Z") || iso.range(of: tzRegex, options: .regularExpression) != nil
        
        if hasTZ {
            let iso1 = ISO8601DateFormatter()
            iso1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = iso1.date(from: iso) { return d }
            
            let iso2 = ISO8601DateFormatter()
            iso2.formatOptions = [.withInternetDateTime]
            return iso2.date(from: iso)
        }
        
        // 2) 타임존이 없는 경우: KST로 해석
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = kst
        for pattern in ["yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm"] {
            fmt.dateFormat = pattern
            if let d = fmt.date(from: iso) { return d }
        }
        return nil
    }
    
    private func isLess(_ a: CourseUIModel, _ b: CourseUIModel) -> Bool {
        let at = a.course.totalTime ?? .max
        let bt = b.course.totalTime ?? .max
        if at != bt { return at < bt }
        
        let ad = (a.course.departureDateTime.flatMap { parseServerDate($0) }) ?? Date.distantFuture
        let bd = (b.course.departureDateTime.flatMap { parseServerDate($0) }) ?? Date.distantFuture
        if ad != bd { return ad < bd }
        
        return a.id < b.id
    }
    
    // MARK: - 새벽 03~05시 검색 확인
    func isBlackoutNow() -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = kst
        let hour = cal.component(.hour, from: Date())
        // 00:00 <= now < 05:00
        return hour >= 0 && hour < 5
    }
}

extension CourseSearchViewModel {
    
    // 걷는 시간 측정
    private func walkMetric(of course: Course) -> Int {
        let walks = course.totalWalkTime ?? 0
        return walks
    }
    
    private func departureDate(of course: Course) -> Date {
        (course.departureDateTime.flatMap { parseServerDate($0) }) ?? .distantPast
    }
    
    private func totalTime(of course: Course) -> Int {
        course.totalTime ?? Int.max
    }
    
    private func transferCount(of course: Course) -> Int {
        let count = course.legs.filter { $0.mode == .bus || $0.mode == .subway }.count
        return max(0, count - 1)
    }
    
    private func rankIndex<T: Comparable>(
        value: T,
        in values: [T],
        order: SortOrder
    ) -> Int {
        let sorted = (order == .forward) ? values.sorted() : values.sorted(by: >)
        // 동점일 때는 “가장 좋은 순위”로
        guard let firstIdx = sorted.firstIndex(of: value) else { return values.count }
        return firstIdx + 1
    }
    
    enum SortOrder { case forward, reverse }
    
    // 외부에서 호출: 선택된 코스의 순위 계산
    func ranks(for selected: Course) -> RouteRanks {
        // 현재 탭 정렬과 무관하게 “전체 후보(allCourses)” 기준으로 순위 산정
        let courses = allCourses.map { $0.course }
        
        let depValues   = courses.map { departureDate(of: $0) }   // 늦을수록 1위 ⇒ 내림차순
        let walkValues  = courses.map { walkMetric(of: $0) }       // 적을수록 1위 ⇒ 오름차순
        let timeValues  = courses.map { totalTime(of: $0) }        // 짧을수록 1위 ⇒ 오름차순
        
        let laterDepRank  = rankIndex(value: departureDate(of: selected), in: depValues,  order: .reverse)
        let minWalkRank   = rankIndex(value: walkMetric(of: selected),   in: walkValues, order: .forward)
        let minTimeRank   = rankIndex(value: totalTime(of: selected),    in: timeValues, order: .forward)
        let transfers     = transferCount(of: selected)
        
        return RouteRanks(
            laterDepartureTimeRank: laterDepRank,
            minimalWalkRank:        minWalkRank,
            minimalTotalTimeRank:   minTimeRank,
            transferCount:          transfers
        )
    }
}
