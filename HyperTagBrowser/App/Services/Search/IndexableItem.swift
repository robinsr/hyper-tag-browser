// created on 12/25/24 by robinsr

import AppKit
import Factory
import CoreSpotlight
import GRDB


protocol IndexableItem: Identifiable {
  typealias Metadata = [String: Any?]
  
  static func from(attributeSet: CSSearchableItemAttributeSet, metadata: Metadata) -> Self?
  
  func attributeSet(in domain: String) -> CSSearchableItemAttributeSet
  func asSearchableItem(in domain: String) -> CSSearchableItem
}


extension IndexableItem {
  
  var debugDescription: String {
    let attrs = self.attributeSet(in: "DOMAIN")
    if let jsonAttributes = try? JSONEncoder.tryPretty(attrs) {
      return jsonAttributes
    } else {
      return """
      IndexableItem(attributeSet: \(attrs))
      """
    }
  }
}
 

extension IndexInfoRecord: IndexableItem {
  
  func asSearchableItem(in domainId: String) -> CSSearchableItem {
    return CSSearchableItem(
      uniqueIdentifier: id.value,
      domainIdentifier: domainId,
      attributeSet: attributeSet(in: domainId)
    )
  }
  
  func attributeSet(in domainId: String) -> CSSearchableItemAttributeSet {
    let indxRecord = self.index
    let tags = self.searchableTags
    
    let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.contentItem)
    
    attributeSet.domainIdentifier = domainId
    attributeSet.contentCreationDate = indxRecord.created
    attributeSet.contentDescription = "Indexed by \(Constants.appDisplayName)"
    attributeSet.contentType = indxRecord.type.identifier
    attributeSet.contentTypeTree = [indxRecord.type.identifier, UTType.contentItem.identifier]
    attributeSet.displayName = indxRecord.name
    attributeSet.title = indxRecord.name
    attributeSet.identifier = indxRecord.id.value
    attributeSet.keywords = tags.map(\.rawValue)
    attributeSet.lastUsedDate = Date.now
    attributeSet.contentURL = indxRecord.url.absoluteURL
    attributeSet.url = indxRecord.url.absoluteURL
    
    return attributeSet
  }
  
  static func from(attributeSet attrs: CSSearchableItemAttributeSet, metadata: Metadata = [:]) -> Self? {
    
    guard let contentURL = attrs.contentURL else { return nil }
    
    guard FileManager.default.fileExists(at: contentURL) else { return nil }
    
    let index = IndexRecord(row: Row([
      "comment": "", // JSONEncoder.pretty(metadata)
      "created": attrs.contentCreationDate ?? Date.distantPast,
      "id": ContentId(existing: attrs.identifier ?? .randomIdentifier(24, prefix: "searchresult:")),
      "isIndexed": false,
      "location": contentURL.directoryURL.filepath,
      "modified": attrs.contentModificationDate ?? Date.distantPast,
      "name": contentURL.filename,
      "timestamp": Date.now,
      "size": attrs.fileSize ?? 0,
      "type": UTType(filenameExtension: contentURL.pathExtension) ?? .item,
      "visibility": ContentItemVisibility.normal,
      "volume": contentURL.volumeName,
    ]))
    
    let keywords = attrs.keywords ?? []
    
    let tags = keywords
      .compactMap { FilteringTag.init($0) }
      .filter { $0.type.domain.oneOf(.descriptive, .attribution) }
      .map { (tag: FilteringTag) in
        IndexTagValueRecord.init(
          id: .randomIdentifier(12, prefix: "tagitem:"),
          tagId: .randomIdentifier(24, prefix: "tag:"),
          contentId: index.id,
          value: tag)
    }
    
    return IndexInfoRecord.init(
      index: index,
      tagValues: tags,
      queueItems: []
    )
  }
}


extension CSSearchableItemAttributeSet: @retroactive Encodable {
  enum CodingKeys: String, CodingKey {
    case title
    case contentDescription
    case thumbnailData
    case thumbnailURL
    case contentCreationDate
    case contentURL
    case keywords
    case identifier
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(title, forKey: .title)
    try container.encode(contentDescription, forKey: .contentDescription)
    try container.encode(thumbnailData, forKey: .thumbnailData)
    try container.encode(thumbnailURL, forKey: .thumbnailURL)
    try container.encode(contentCreationDate, forKey: .contentCreationDate)
    try container.encode(contentURL, forKey: .contentURL)
    try container.encode(keywords, forKey: .keywords)
    try container.encode(identifier, forKey: .identifier)
  }
}

extension CSSearchableItem: @retroactive Encodable {
  enum CodingKeys: String, CodingKey {
    case uniqueIdentifier
    case domainIdentifier
    case attributeSet
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(uniqueIdentifier, forKey: .uniqueIdentifier)
    try container.encode(domainIdentifier, forKey: .domainIdentifier)
    try container.encode(attributeSet, forKey: .attributeSet)
  }
}
