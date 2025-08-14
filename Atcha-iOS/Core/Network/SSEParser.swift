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
    
    // 옵션: 너무 커지면 리셋
    private let maxBufferBytes = 2_000_000
    
    /// chunk 를 누적하고, 완성된 이벤트들만 반환
    func feed(_ chunk: Data) -> [SSEEvent] {
        if buffer.isEmpty {
            // UTF-8 BOM 제거 (가끔 서버가 붙이는 경우가 있음)
            let bom: [UInt8] = [0xEF, 0xBB, 0xBF]
            if chunk.starts(with: bom) {
                buffer.append(chunk.dropFirst(3))
            } else {
                buffer.append(chunk)
            }
        } else {
            buffer.append(chunk)
        }
        
        var events: [SSEEvent] = []
        
        // LF, CRLF 모두 지원
        let lf2 = Data("\n\n".utf8)
        let crlf2 = Data("\r\n\r\n".utf8)
        
        while true {
            guard let range = buffer.range(of: lf2) ?? buffer.range(of: crlf2) else { break }
            let frame = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
            buffer.removeSubrange(buffer.startIndex..<range.upperBound)
            
            if let text = String(data: frame, encoding: .utf8) {
                // 필요 시 원본 프레임 로깅
                // print("📥 SSE Raw Frame:\n\(text)")
                events.append(parseFrame(text))
                current = SSEEvent()
            } else {
                // UTF-8 경계가 어긋난 경우 다음 chunk 를 기다린다.
                // 프레임을 다시 버퍼 앞으로 되돌리는 전략도 가능하지만,
                // 보통 다음 feed 에서 정상 복구됨.
                continue
            }
        }
        
        if buffer.count > maxBufferBytes {
            print("⚠️ SSEParser buffer too large. Resetting.")
            buffer.removeAll(keepingCapacity: false)
        }
        
        return events
    }
    
    private func parseFrame(_ text: String) -> SSEEvent {
        var ev = SSEEvent()
        
        // CRLF → LF 정규화
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        
        for raw in normalized.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            if line.isEmpty { continue }
            if line.hasPrefix(":") { continue } // heartbeat/comment
            
            // "key: value" 또는 "key:value" 모두 허용
            if line.hasPrefix("data:") {
                var v = line.dropFirst(5) // drop "data:"
                if v.first == " " { v = v.dropFirst() }
                let piece = String(v)
                ev.data.isEmpty ? (ev.data = piece) : (ev.data += "\n" + piece)
            } else if line.hasPrefix("id:") {
                var v = line.dropFirst(3)
                if v.first == " " { v = v.dropFirst() }
                ev.id = String(v)
            } else if line.hasPrefix("event:") {
                var v = line.dropFirst(6)
                if v.first == " " { v = v.dropFirst() }
                ev.event = String(v)
            }
        }
        return ev
    }
}
