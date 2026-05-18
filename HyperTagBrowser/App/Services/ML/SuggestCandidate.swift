// created on 8/13/25 by robinsr

import GenericJSON

struct SuggestCandidate {
  let tag: String
  let score: Double
  let rationale: String?
}

extension SuggestCandidate {
  init?(jsonRow: [JSON]) {
    // Expect at least ["name", score]
    guard jsonRow.count >= 2 else { return nil }

    // 0: tag name
    guard case let .string(tag) = jsonRow[0] else { return nil }

    // 1: score (number)
    let score: Double
    switch jsonRow[1] {
    case let .number(d): score = d
    case let .bool(b):   score = b ? 1.0 : 0.0  // defensive fallback
    default:             return nil
    }

    // 2: rationale (optional string)
    var rationale: String? = nil
    if jsonRow.count > 2, case let .string(r) = jsonRow[2] {
      rationale = r
    }

    self.tag = tag
    self.score = score
    self.rationale = rationale
  }
}
