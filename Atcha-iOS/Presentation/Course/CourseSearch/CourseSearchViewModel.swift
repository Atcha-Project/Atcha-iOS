//
//  CourseSearchViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/3/25.
//

import Foundation

final class CourseSearchViewModel: BaseViewModel {
    @Published var courses: [Course] = []
    
    // MARK: - 탭별 코스
    func fetchCourses(for tabIndex: Int) {
        switch tabIndex {
        case 0:
            self.courses = [
                Course(
                    routedId: "3aae204e-10b9-405e-b613-2ae391b6d8dc",
                    departureDateTime: "2021-09-01T07:00:00",
                    totalTime: 872,
                    totalWalkTime: 300,
                    transferCount: 0,
                    totalDistance: 4066,
                    totalWalkDistance: 324,
                    pathType: 1,
                    legs: [
                        legs(
                            distance: 181,
                            sectionTime: 167,
                            mode: "WALK",
                            departureDateTime: nil,
                            type: nil,
                            service: nil,
                            start: addressInfo(
                                name: "출발지",
                                lon: "126.975131",
                                lan: "37.563936"
                            ),
                            end: addressInfo(
                                name: "시청",
                                lon: "126.975494",
                                lan: "37.563625"
                            ),
                            passStopList: [],
                            step: [
                                step(
                                    streetName: "보행자도로",
                                    distance: 48,
                                    description: "보행자도로를 따라 48m 이동",
                                    linestring: "126.975044,37.56403 126.97498,37.564003"
                                )
                            ],
                            passShape: ""
                        ),
                        legs(
                            distance: 3951,
                            sectionTime: 572,
                            mode: "SUBWAY",
                            departureDateTime: "2021-09-01T07:12:00",
                            type: 9,
                            service: 0,
                            start: addressInfo(
                                name: "시청",
                                lon: "126.975494",
                                lan: "37.563625"
                            ),
                            end: addressInfo(
                                name: "신당",
                                lon: "127.019483",
                                lan: "37.565678"
                            ),
                            passStopList: [
                                passStopList(index: 0, stationId: nil, stationName: "시청", lon: "126.975494", lan: "37.563625"),
                                passStopList(index: 1, stationId: nil, stationName: "신당", lon: "126.982275", lan: "37.566042")
                                
                            ],
                            step: [],
                            passShape: "126.975703,37.563706 126.976047,37.563836"
                        ),
                        legs(
                            distance: 143,
                            sectionTime: 133,
                            mode: "WALK",
                            departureDateTime: nil,
                            type: nil,
                            service: nil,
                            start: addressInfo(
                                name: "신당",
                                lon: "127.019483",
                                lan: "37.565678"
                            ),
                            end: addressInfo(
                                name: "도착지",
                                lon: "127.020235",
                                lan: "37.565698"
                            ),
                            passStopList: [],
                            step: [
                                step(
                                    streetName: nil,
                                    distance: 80,
                                    description: "80m 이동",
                                    linestring: "127.01948,37.565662 127.019516,37.565662"
                                )
                            ],
                            passShape: ""
                        )
                    ]
                )
            ]
        case 1:
            self.courses = []
        case 2:
            self.courses = []
        default:
            self.courses = []
        }
    }
}
