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
    
    let courseUseCase: CourseUseCase
    private let startLat: String
    private let startLon: String
    public private(set) var startAddress: String
    
    init(
        courseUseCase: CourseUseCase,
        startLat: String,
        startLon: String,
        startAddress: String
    ) {
        self.courseUseCase = courseUseCase
        self.startLat = startLat
        self.startLon = startLon
        self.startAddress = startAddress
        super.init()
    }
    
    
    // MARK: - 탭별 코스
    func fetchCourses(for tabIndex: Int) {
        switch tabIndex {
        case 0:
            // BUS + SUBWAY 포함된 코스만
            if courses != allCourses {
                self.courses = allCourses
            }
        case 1:
            // BUS만 포함된 코스
            self.courses = allCourses.filter { uiModel in
                let modes = uiModel.course.legs.map { $0.modeEnum }
                return !modes.contains(.subway) && modes.contains(.bus)
            }
            
        case 2:
            // SUBWAY만 포함된 코스
            self.courses = allCourses.filter { uiModel in
                let modes = uiModel.course.legs.map { $0.modeEnum }
                return !modes.contains(.bus) && modes.contains(.subway)
            }
        default:
            self.courses = []
        }
    }
    
    // MARK: - 코스 검색
    func courseSearch() {
        Task {
            do {
                let userDefaults = UserDefaultsWrapper()
                let endLat = userDefaults.string(forKey: UserDefaultsWrapper.Key.lat.rawValue) ?? "37.554722"
                let endLon = userDefaults.string(forKey: UserDefaultsWrapper.Key.lon.rawValue) ?? "126.970833"
                
                let request = CourseSearchRequest(startLat: startLat, startLon: startLon, endLat: endLat, endLon: endLon, sortType: 1)
                
                let response = try await courseUseCase.courseSearch(request)
                
                let uiModels = response.map {
                    CourseUIModel(id: $0.routedId ?? UUID().uuidString, course: $0, isExpanded: false)
                }
                
                self.allCourses = uiModels
                self.fetchCourses(for: 0)
            } catch {
                print("탭별 코스 가져오기 실패: \(error)")
            }
        }
    }
    
    // MARK: UI 확장을 위한 토글 함수
    func toggleExpanded(for model: CourseUIModel) {
        guard let index = courses.firstIndex(of: model) else { return }
        
        var newModel = courses[index]
        newModel.isExpanded.toggle()
        courses[index] = newModel
    }
}

