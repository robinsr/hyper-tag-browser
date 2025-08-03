// created on 11/22/24 by robinsr

import Foundation
import IdentifiedCollections



/**
 * A specialized dictionary that maps `ContentPointer` to `URL`
 *
 * The whole idea of this is a sorta bandaid to file reference pointers not being reliable across app launches.
 * Ideally we could just use a FileReferenceURL to locate a tracked file regardless of it being moved or renamed,
 * but file reference URLs are temporary.
 *
 * A "ContentPointer" stores the contentId of a file (generally immutable, attached directly to file as extened attribute)
 * and basically the *last known location* of the file.
 *
 * If a file with that X-Content-ID attribute is at that location, great! If not, we will have to locate via its contentId
 * extended attribute (if it even exists).
 *
 * This specialized dictionary is just a convenience/QOL object to support the common operation of exchanging a
 * ContentPointer (URL + last known location) to a real FileURL on disk
 */
struct ContentPointerURLMapping: Codable {
  
  typealias DictionaryType = [ContentPointer: URL]
  typealias SubDictionaryType = [ContentId: URL]
  
  private var contents = DictionaryType()
  private var subcontents = SubDictionaryType()
  
  init(contents: DictionaryType) {
    self.contents = contents
    
    self.subcontents = contents.reduce(into: SubDictionaryType()) { result, pair in
      result[pair.key.contentId] = pair.value
    }
  }
}

extension ContentPointerURLMapping: Collection {
  // Required nested types, that tell Swift what our collection contains
  typealias Index = DictionaryType.Index
  typealias Element = DictionaryType.Element

  // The upper and lower bounds of the collection, used in iterations
  var startIndex: Index { return contents.startIndex }
  var endIndex: Index { return contents.endIndex }

  // Required subscript, based on a dictionary index
  subscript(index: Index) -> Iterator.Element {
    get { return contents[index] }
  }

  // Method that returns the next index when iterating
  func index(after i: Index) -> Index {
    return contents.index(after: i)
  }
}

extension ContentPointerURLMapping {
  subscript(id: ContentId) -> URL? {
    get { return subcontents[id] }
  }
  
  subscript(pointer: ContentPointer) -> URL? {
    get { return contents[pointer] }
  }
  
  subscript(url url: URL) -> ContentPointer? {
    get { contents.first(where: { $0.value == url })?.key }
  }
  
  subscript(at index: Int) -> Element {
    get { return contents[contents.values.index(contents.values.startIndex, offsetBy: index)] }
  }

  mutating func insert(_ pointer: ContentPointer, at url: URL) {
    if !contents.has(key: pointer) {
      contents[pointer] = url
    }
    
    if !subcontents.has(key: pointer.contentId) {
      subcontents[pointer.contentId] = url
    }
  }
  
  var count: Int {
    contents.count
  }
}
