//
//  FileStorageImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/26/25.
//

import Foundation

actor FileStorageImpl<T: FileStorable>: FileStorage {
    private let maxCount: Int
    public init(maxCount: Int = 20) {
        self.maxCount = maxCount
    }
    
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(T.fileName)
    }
    
    public func fetch() async -> [T] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            return []
        }
    }
    
    public func save(item: T) async {
        var list = await fetch()
        list.removeAll { $0 == item }
        list.insert(item, at: 0)
        if list.count > maxCount {
            list.removeLast()
        }
        await overwrite(list)
    }
    
    public func delete(item: T) async {
        var list = await fetch()
        list.removeAll { $0 == item }
        await overwrite(list)
    }
    
    public func clearAll() async {
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    private func overwrite(_ list: [T]) async {
        do {
            let data = try JSONEncoder().encode(list)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("❌ 저장 실패: \(error)")
        }
    }
}
