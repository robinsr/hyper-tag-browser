// created on 8/13/25 by robinsr

import Foundation
import GenericJSON

struct MLGenericResponse: Decodable {
    let ok: Bool
    let id: String?
    let error: String?
    let model: String?
    // If helper emits floats, decoding to [Double] is most robust.
    let vector: [Double]?
    // [["tag", score, "rationale"], ...] as heterogeneous arrays
    let suggest: [[JSON]]?
    let metrics: [String: JSON]?
}

struct PingResponse: Decodable {
    let ok: Bool
    let id: String?
    // metrics like {"time": 1755123887}
    let metrics: [String: JSON]?
}

struct EmbedImageResponse: Decodable {
    let ok: Bool
    let id: String?
    let model: String?
    let vector: [Double]?
    let error: String?
}

struct SuggestTagsResponse: Decodable {
    let ok: Bool
    let id: String?
    let suggest: [[JSON]]?
    let metrics: [String: JSON]?
    let error: String?
}
