//
//  AppVersionRepository.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation

protocol AppVersionRepository {
    func fetchAppVersion() async throws -> String
    func updateAppVersion(version: AppVersionRequest) async throws -> APIEmptyResponse
}
