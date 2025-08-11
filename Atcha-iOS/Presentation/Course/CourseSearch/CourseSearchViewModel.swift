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
    
    var getAlarmTapped: ((String, LegInfo) -> Void)?
    var getDetailTapped: ((String, LegInfo) -> Void)?
    
    private let kst = TimeZone(identifier: "Asia/Seoul")!
    private let cutoffHour = 5
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
            base = allCourses
        case 1:
            // BUS만 포함
            base = allCourses.filter { m in
                let modes = m.course.legs.compactMap { $0.mode }
                return !modes.contains(.subway) && modes.contains(.bus)
            }
        case 2:
            // SUBWAY만 포함
            base = allCourses.filter { m in
                let modes = m.course.legs.compactMap { $0.mode }
                return !modes.contains(.bus) && modes.contains(.subway)
            }
        default:
            base = []
        }

        // 2) 정렬: totalTime ↑, 같으면 departureDateTime ↑
        let sorted = base.sorted(by: isLess(_:_:))

        // 3) 변경이 있을 때만 갱신 (불필요한 리렌더 방지)
        if courses != sorted {
            self.courses = sorted
        }
    }
    
    // MARK: - 코스 검색
    func courseSearch() {
        Task {
            do {
                let userDefaults = UserDefaultsWrapper.shared
                let endLat = userDefaults.string(forKey: UserDefaultsWrapper.Key.homeLat.rawValue) ?? "37.554722"
                let endLon = userDefaults.string(forKey: UserDefaultsWrapper.Key.homeLon.rawValue) ?? "126.970833"
                
                let request = CourseSearchRequest(startLat: startLat, startLon: startLon, endLat: endLat, endLon: endLon, sortType: 1)
                
                let response = try await courseUseCase.courseSearch(request)
                
                let uiModels = response.map {
                    CourseUIModel(id: $0.routeId ?? UUID().uuidString, course: $0, isExpanded: false)
                }
                
                self.allCourses = uiModels
                self.fetchCourses(for: 0)
            } catch {
                print("탭별 코스 가져오기 실패: \(error)")
                self.isServerError = true
                self.courses = []
            }
        }
    }
    
    // MARK: - 코스 검색 스트리밍용
    func startCourseStream() {
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
                    endLon: endLon,
                    sortType: 1
                )
                
                var hasReceived = false
                
                for try await course in courseUseCase.observeCourseStream(request) {
                    guard let anchor = self.anchorDate,
                          let isoString = course.departureDateTime,
                          let dep = self.parseServerDate(isoString),
                          self.isInWindow(dep, anchor: anchor) else {
                        continue
                    }
                    setLoading(false)
                    hasReceived = true
                    
                    let uiModel = CourseUIModel(id: course.routeId ?? UUID().uuidString,
                                                course: course, isExpanded: false)
                    if !self.allCourses.contains(where: { $0.id == uiModel.id }) {
                        self.allCourses.append(uiModel)
                        self.allCourses.sort(by: isLess(_:_:))
                        self.fetchCourses(for: 0)
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
                print("알림 등록 실패: \(error)")
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
    
    // MARK: - anchor 기준 "다음 05:00" 계산
    private func nextCutoff5am(after anchor: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = kst

        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: anchor)

        if (comps.hour ?? 0) < cutoffHour {
            comps.hour = cutoffHour; comps.minute = 0; comps.second = 0
            return cal.date(from: comps)!
        } else {
            // 다음 날 05:00
            if let dayAdded = cal.date(byAdding: .day, value: 1, to: anchor) {
                var next = cal.dateComponents([.year, .month, .day], from: dayAdded)
                next.hour = cutoffHour; next.minute = 0; next.second = 0
                return cal.date(from: next)!
            }
            return anchor // fallback
        }
    }
    
    // MARK: - 윈도우 체크: [anchor, next 05:00]
    private func isInWindow(_ dep: Date, anchor: Date) -> Bool {
        let upper = nextCutoff5am(after: anchor)
        return dep >= anchor && dep <= upper
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
}





