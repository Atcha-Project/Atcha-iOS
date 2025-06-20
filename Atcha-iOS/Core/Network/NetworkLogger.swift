//
//  NetworkLogger.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Alamofire
import Foundation

final class NetworkLogger: EventMonitor {
    let queue = DispatchQueue(label: "networklogger.queue")
    
    func requestDidFinish(_ request: Request) {
        print("Request: \(request.description)")
    }
    
    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        print("Response: \(response.debugDescription)")
    }
}
