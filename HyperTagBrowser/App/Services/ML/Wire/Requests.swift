// created on 8/13/25 by robinsr

import Foundation
import GenericJSON

protocol MLRequest: Encodable {
  var id: String { get }
  var cmd: String { get }
}

// {"id":"...", "cmd":"ping"}
struct PingRequest: MLRequest {
  let id: String
  let cmd: String = "ping"
  init(id: String = UUID().uuidString) { self.id = id }
}

// {"id":"...", "cmd":"embed_image", "path":"/path/to/file"}
struct EmbedImageRequest: MLRequest {
  let id: String
  let cmd: String = "embed_image"
  let path: String
  init(path: String, id: String = UUID().uuidString) {
    self.path = path
    self.id = id
  }
}

// {"id":"...", "cmd":"suggest_tags", "fileEmbedding":[...], "tagEmbeddings":[["name",[...]], ...]}
struct SuggestTagsRequest: MLRequest {
  let id: String
  let cmd: String = "suggest_tags"
  let fileEmbedding: [Float]
  let tagEmbeddings: [[JSON]]

  init(fileEmbedding: [Float], tagEmbeddings: [(String, [Float])], id: String = UUID().uuidString) {
    self.id = id
    self.fileEmbedding = fileEmbedding
    self.tagEmbeddings = tagEmbeddings.map { (name, vec) in
      [
        .string(name),
        .array(vec.map {
          .number(Double($0))
        })
      ]
    }
  }
}
