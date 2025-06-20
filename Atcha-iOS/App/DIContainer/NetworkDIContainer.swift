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
    
    func makeSession() -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = NetworkConstant.timeoutInterval
        
        return Session(
            configuration: configuration,
            interceptor: TokenInterceptor(tokenStorage: tokenStorage),
            eventMonitors: [NetworkLogger()]
        )
    }
    
    func makeAPIService() -> APIService {
        return APIServiceImpl(session: makeSession())
    }
}
