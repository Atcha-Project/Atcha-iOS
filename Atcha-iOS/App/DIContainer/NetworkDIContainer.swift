//
//  NetworkDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation
import Alamofire

final class NetworkDIContainer {
    private let tokenStorage: TokenStorage
    
    init(tokenStorage: TokenStorage) {
        self.tokenStorage = tokenStorage
    }
    
    func makeSession(useInterceptor: Bool = true) -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = NetworkConstant.timeoutInterval

        let interceptor: RequestInterceptor? = useInterceptor ? TokenInterceptor(tokenStorage: tokenStorage) : nil

        return Session(
            configuration: configuration,
            interceptor: interceptor,
            eventMonitors: [NetworkLogger()]
        )
    }
    
    func makeAPIService(useInterceptor: Bool = true) -> APIService {
        return APIServiceImpl(session: makeSession(useInterceptor: useInterceptor))
    }
}

