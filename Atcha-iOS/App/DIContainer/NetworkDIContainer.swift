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
    
    // 인터셉터가 있는 세션 (메모리 유지를 위해 프로퍼티로 선언)
    private lazy var authenticatedSession: Session = makeSession(useInterceptor: true)
    
    // 인터셉터가 없는 세션 (로그인용)
    private lazy var publicSession: Session = makeSession(useInterceptor: false)

    init(tokenStorage: TokenStorage) {
        self.tokenStorage = tokenStorage
    }
    
    private func makeSession(useInterceptor: Bool) -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = NetworkConstant.timeoutInterval

        let interceptor: RequestInterceptor?
        if useInterceptor {
            interceptor = TokenInterceptor(
                tokenStorage: tokenStorage,
                refreshSession: publicSession 
            )
        } else {
            interceptor = nil
        }

        let evaluators: [String: ServerTrustEvaluating] = [
            "atcha.p-e.kr": DisabledTrustEvaluator(),
            "atcha.online": DisabledTrustEvaluator()
        ]
        let trustManager = ServerTrustManager(evaluators: evaluators)

        return Session(
            configuration: configuration,
            interceptor: interceptor,
            serverTrustManager: trustManager,
            eventMonitors: [NetworkLogger()]
        )
    }
    
    // APIService 생성 시 미리 만들어둔(공유된) 세션을 주입합니다.
    func makeAPIService(useInterceptor: Bool = true) -> APIService {
        let session = useInterceptor ? authenticatedSession : publicSession
        return APIServiceImpl(session: session)
    }
}
