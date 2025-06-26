//
//  FileStorage.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/26/25.
//

import Foundation

protocol FileStorage {
    associatedtype Item: FileStorable

    func fetch() async -> [Item]
    func save(item: Item) async
    func delete(item: Item) async
    func clearAll() async
}
