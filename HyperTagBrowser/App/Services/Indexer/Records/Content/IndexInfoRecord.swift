// created on 10/23/24 by robinsr

import Foundation
import GRDB
import CustomDump
import System
import UniformTypeIdentifiers


/**
 A joined type consisting of a single ``IndexRecord`` and its associations.

 It is a joined type consisting of:
 
 - `tagValues`  - Array of ``IndexTagValueRecord`` - The record's joins with ``TagRecord``
 - `queueItems` - Array of ``QueueItemRecord`` - The record's joins with ``QueueRecord``
 - `tagCount`   - The number of tags applied to the indexrecord, as `Int`
*/
struct IndexInfoRecord: Identifiable, FetchableRecord, Codable {
  var index: IndexRecord
  var tagValues: [IndexTagValueRecord]
  var queueItems: [QueueItemRecord]
  var tagCount: Int = 0
  
  static func == (lhs: IndexInfoRecord, rhs: IndexInfoRecord) -> Bool {
    lhs.id == rhs.id
  }
  
  enum CodingKeys: String, CodingKey {
    case index, tagValues, tagCount, queueItems
  }
  
  enum Columns: String, ColumnExpression {
    case index, tagValues, tagCount, queueItems
  }
  
  static func fromURL(_ url: URL, _ pointer: ContentPointer) -> IndexInfoRecord? {
    let namedata = FilenameData(fileURL: url)
    let keywordTags = namedata.inBracesValues.map { tag in FilteringTag.tag(tag) }
    let creditTags = namedata.inBracketValues.map { tag in FilteringTag.creator(tag) }
    
    let tagValues = (keywordTags + creditTags).map { tag in
      IndexTagValueRecord(
        id: .randomIdentifier(8),
        tagId: tag.rawValue,
        contentId: pointer.contentId,
        value: tag)
    }

    return try? IndexInfoRecord(
      index: IndexRecord(fileURL: url, contentId: pointer.contentId),
      tagValues: tagValues,
      queueItems: [])
  }
}


extension IndexInfoRecord {
  
  private typealias Indx = IndexRecord
  private typealias IndxCols = IndexRecord.Columns
  private typealias IndxVirt = IndexRecord.VirtualColumns
  
  typealias InfoRequest = QueryInterfaceRequest<IndexInfoRecord>
  
  static private let defaultIndexRecordCols: [any SQLSelectable] = [
    .allColumns, Indx.TableAliases.tagCount.forKey("tagCount")
  ]
  
  static func info(matching params: IndxRequestParams) -> InfoRequest {
    IndexRecord
      .all()
      .select(params.sqlSelections)
      .joiningTagValues()
      .joiningTagCount()
      .joiningQueueItems()
      .applyingParams(params)
      .limit(params.limit, offset: params.offset)
      .order(IndxVirt.isFolder.detached.desc, params.sqlOrdering)
      .asRequest(of: IndexInfoRecord.self)
  }
  
  static func info(ids: [ContentId]) -> InfoRequest {
    IndexRecord
      .all()
      .select(Self.defaultIndexRecordCols)
      .withContentId(ids)
      .joiningTagValues()
      .joiningTagCount()
      .joiningQueueItems()
      .asRequest(of: IndexInfoRecord.self)
  }
  
  static func info(id: ContentId) -> InfoRequest {
    IndexRecord
      .all()
      .select(Self.defaultIndexRecordCols)
      .withContentId(id)
      .joiningTagValues()
      .joiningTagCount()
      .joiningQueueItems()
      .asRequest(of: IndexInfoRecord.self)
  }
}


extension IndexInfoRecord: DisplayableContentItem {
  var id: ContentId { index.contentId }
  var pointer: ContentPointer { index.pointer }
  
  var url: URL { index.url }
  var filepath: FilePath { index.filepath }
  var location: FilePath { index.location }
  var name: String { index.name}
  
  var exists: Bool { index.fileExists ?? false }
  var tags: [FilteringTag] { tagValues.map(\.asFilter) }
  var link: Route { index.link }
  
  
  func conforms(to uttype: UTType) -> Bool {
    index.type.conforms(to: uttype)
  }
  
  func diverges(from uttype: UTType) -> Bool {
    index.type.diverges(from: uttype)
  }
  
  var searchableTags: [FilteringTag] {
    var searchtags = self.tags
    
    searchtags.append(.created(.init(date: index.created, bounds: .on)))
    
    for queue in queueItems {
      // TODO: This should be `.queue(queue.name)`, name is only available on QueueRecord, not QueueItemRecord
      searchtags.append(.queue(queue.id))
    }
    
    return searchtags
  }
}

extension IndexInfoRecord: ThumbnailableContentItem {
  var fileURL: URL { index.url }
  var contentType: UTType { index.type }
}
