//
//  FileStorable.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/26/25.
//

import Foundation

protocol FileStorable: Codable & Equatable {
    static var fileName: String { get }
}
