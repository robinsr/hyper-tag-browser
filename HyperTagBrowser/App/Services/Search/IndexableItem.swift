// created on 12/25/24 by robinsr

import AppKit
import Factory
import CoreSpotlight
import GRDB


protocol IndexableItem: Identifiable {
  typealias AttributeSet = CSSearchableItemAttributeSet
  typealias Metadata = [String: Any?]
  
  var attributeSet: AttributeSet { get }

  static func from(attributeSet: AttributeSet, metadata: Metadata) -> Self?
}


extension IndexableItem {
  
  var searchIndexName: String {
    Container.shared.spotlightServiceIndexName()
  }
  
  var domainIdentifier: String {
    Container.shared.spotlightDomainIdentifier()
  }
  
  var qlService: QuicklookService {
    Container.shared.quicklookService()
  }
  
  var descriptionSuffix: String {
    let app = Constants.appname
    let date = DateFormatter.medium.string(from: Date.now)
    
    return "indexed by \(app) on \(date) to index \(searchIndexName)"
  }
}


extension IndexInfoRecord: IndexableItem {
  
  var attributeSet: CSSearchableItemAttributeSet {
    let logger = EnvContainer.shared.logger("IndexInfoRecord/IndexableItem")
    
    let item = self.index
    let id = self.id
    let tags = self.searchableTags
    
    
    let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.contentItem)
    
    attributeSet.domainIdentifier = self.domainIdentifier
    attributeSet.contentCreationDate = item.created
    attributeSet.contentDescription = "\(item.type.localizedDescription ?? "File") \(self.descriptionSuffix)"
    attributeSet.contentType = item.type.identifier
    attributeSet.contentTypeTree = [item.type.identifier, UTType.contentItem.identifier]
    attributeSet.displayName = item.name
    attributeSet.title = item.name
    attributeSet.identifier = id.value
    attributeSet.keywords = tags.map(\.rawValue)
    attributeSet.lastUsedDate = Date.now
    attributeSet.contentURL = item.url.absoluteURL
    attributeSet.url = item.url.absoluteURL
    
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
