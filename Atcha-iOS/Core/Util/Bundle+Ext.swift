//
//  Bundle+Ext.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/23/25.
//

import Foundation

extension Bundle {
    var kakaoApiKey: String {
        guard let key = object(forInfoDictionaryKey: "KAKAO_API_KEY") as? String else {
            fatalError("KAKAO_API_KEY not found")
        }
        return key
    }

    var kakaoInitKey: String {
        guard let key = object(forInfoDictionaryKey: "KAKAO_INIT_KEY") as? String else {
            fatalError("KAKAO_INIT_KEY not found")
        }
        return key
    }
    
    var tMapKey: String {
        guard let key = object(forInfoDictionaryKey: "TMAP_API_KEY") as? String else {
            fatalError("TMAP_API_KEY not found")
        }
        return key
    }
}

extension Bundle {
    var appVersionWithV: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        return "v\(version)"
    }
}
