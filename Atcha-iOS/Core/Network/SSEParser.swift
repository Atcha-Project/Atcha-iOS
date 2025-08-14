//
//  SSEParser.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/14/25.
//

import Foundation

struct SSEEvent {
var id: String?
var event: String?
var data: String = ""   
}

final class SSEParser {
private var buffer = Data()
private var current = SSEEvent()

func feed(_ chunk: Data) -> [SSEEvent] {
    buffer.append(chunk)
    var events: [SSEEvent] = []

    while let range = buffer.range(of: Data("\n\n".utf8)) {
        let frame = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
        buffer.removeSubrange(buffer.startIndex..<range.upperBound)
        if let text = String(data: frame, encoding: .utf8) {
            events.append(parseFrame(text))
            current = SSEEvent()
        }
    }
    return events
}

private func parseFrame(_ text: String) -> SSEEvent {
    var ev = SSEEvent()
    for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
        if line.isEmpty { continue }
        if line.hasPrefix(":") { continue } // comment/heartbeat
        if line.hasPrefix("data:") {
            let v = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            ev.data.isEmpty ? (ev.data = String(v)) : (ev.data += "\n" + v)
        } else if line.hasPrefix("id:") {
            ev.id = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        } else if line.hasPrefix("event:") {
            ev.event = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
        }
    }
    return ev
}
}
