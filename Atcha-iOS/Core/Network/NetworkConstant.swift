//
//  NetworkConstant.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation

struct NetworkConstant {
    #if DEBUG
    static let baseURL = "https://atcha.p-e.kr/api"
    #else
    static let baseURL = "https://atcha.online/api"
    #endif
    static let timeoutInterval: TimeInterval = 30
}



