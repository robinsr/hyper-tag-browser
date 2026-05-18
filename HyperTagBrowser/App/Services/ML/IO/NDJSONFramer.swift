// Created on 2025-08-13 by robinsr

import Foundation

/// Buffers arbitrary stdout chunks and yields newline-delimited JSON lines.
final class NDJSONFramer {
    private var buffer = Data()
    func push(_ chunk: Data) -> [Data] {
        guard !chunk.isEmpty else { return [] }
        buffer.append(chunk)
        var out: [Data] = []
        while let nl = buffer.firstIndex(of: 0x0A) { // '\n'
            let line = buffer.prefix(upTo: nl)
            out.append(Data(line))
            buffer.removeSubrange(...nl) // drop line + '\n'
        }
        return out
    }
}
