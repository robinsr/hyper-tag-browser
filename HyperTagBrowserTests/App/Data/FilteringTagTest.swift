// created on 1/14/25 by robinsr

import Foundation
import Testing
import Nimble
import CustomDump

@testable import TaggedFileBrowser


@Suite("Data : FilteringTag", .serialized, .tags(.dataModel))
struct FilteringTagTest {
  
  typealias FTagType = FilteringTag.TagType
  
  let cookieTag = FilteringTag("tag|cookie")
  let cookieCreator = FilteringTag("creator|cookie")
  let cookieArtist = FilteringTag("artist|cookie")
  let cookieContributor = FilteringTag("contributor|cookie")
  
  let cookiesCreated = FilteringTag("createdOn|2025-07-04")
  let cookiesCreatedBefore = FilteringTag("createdBefore|2025-07-04")
  let cookiesCreatedAfter = FilteringTag("createdAfter|2025-07-04")
  
  let cookiesModified = FilteringTag("modifiedOn|2025-07-04")
  let cookiesModifiedBefore = FilteringTag("modifiedBefore|2025-07-04")
  let cookiesModifiedAfter = FilteringTag("modifiedAfter|2025-07-04")
  
  let bakingQueue = FilteringTag("queue|Baking TODOs")
  
  let usaDay: Date = Date(unixTimestamp: 1751612400)
  
  
  @Test(".init(rawValue:) - Inits from valid rawValue string")
  func test_filteringtag_init_rawvalue() {
    expect(cookieTag)
      .toNot(beNil())
      .to(map(\.type, equal(.tag)))
      .to(map(\.rawValue, equal("tag")))
      .to(map(\.value, equal("cookie")))
      .to(map(\.rawValue, equal("tag|cookie")))
      .to(map(\.description, equal("cookie")))
      .to(map(\.domain, equal(.descriptive)))
    
    expect(cookieCreator)
      .toNot(beNil())
      .to(map(\.type, equal(.creator)))
      .to(map(\.rawValue, equal("creator")))
      .to(map(\.value, equal("cookie")))
      .to(map(\.rawValue, equal("creator|cookie")))
      .to(map(\.description, equal("Creator: cookie")))
      .to(map(\.domain, equal(.attribution)))
    
    expect(cookieArtist)
      .toNot(beNil())
      .to(map(\.type, equal(.artist)))
      .to(map(\.rawValue, equal("artist")))
      .to(map(\.value, equal("cookie")))
      .to(map(\.rawValue, equal("artist|cookie")))
      .to(map(\.description, equal("Artist: cookie")))
      .to(map(\.domain, equal(.attribution)))
    
    expect(cookieContributor)
      .toNot(beNil())
      .to(map(\.type, equal(.contributor)))
      .to(map(\.rawValue, equal("contributor")))
      .to(map(\.value, equal("cookie")))
      .to(map(\.rawValue, equal("contributor|cookie")))
      .to(map(\.description, equal("Contributor: cookie")))
      .to(map(\.domain, equal(.attribution)))
    
    expect(cookiesCreated)
      .toNot(beNil())
      .to(map(\.type, equal(.createdOn)))
      .to(map(\.rawValue, equal("createdOn")))
      .to(map(\.value, equal("2025-07-04")))
      .to(map(\.rawValue, equal("createdOn|2025-07-04")))
      .to(map(\.description, equal("Created On 7/4/2025")))
      .to(map(\.domain, equal(.creation)))
    
    expect(cookiesCreatedBefore)
      .toNot(beNil())
      .to(map(\.type, equal(.createdBefore)))
      .to(map(\.rawValue, equal("createdBefore")))
      .to(map(\.value, equal("2025-07-04")))
      .to(map(\.rawValue, equal("createdBefore|2025-07-04")))
      .to(map(\.description, equal("Created Before 7/4/2025")))
      .to(map(\.domain, equal(.creation)))
    
    expect(cookiesCreatedAfter)
      .toNot(beNil())
      .to(map(\.type, equal(.createdAfter)))
      .to(map(\.rawValue, equal("createdAfter")))
      .to(map(\.value, equal("2025-07-04")))
      .to(map(\.rawValue, equal("createdAfter|2025-07-04")))
      .to(map(\.description, equal("Created After 7/4/2025")))
      .to(map(\.domain, equal(.creation)))
    
//    expect(cookiesModified)
//      .toNot(beNil())
//      .to(map(\.type, equal(.modifiedOn)))
//      .to(map(\.rawValue, equal("modifiedOn")))
//      .to(map(\.value, equal("2025-07-04")))
//      .to(map(\.rawValue, equal("modifiedOn|2025-07-04")))
//      .to(map(\.description, equal("Modified On 7/4/2025")))
//      .to(map(\.domain, equal(.modification)))
    
//    expect(cookiesModifiedBefore)
//      .toNot(beNil())
//      .to(map(\.type, equal(.modifiedBefore)))
//      .to(map(\.rawValue, equal("modifiedBefore")))
//      .to(map(\.value, equal("2025-07-04")))
//      .to(map(\.rawValue, equal("modifiedBefore|2025-07-04")))
//      .to(map(\.description, equal("Modified Before 7/4/2025")))
//      .to(map(\.domain, equal(.modification)))
    
//    expect(cookiesModifiedAfter)
//      .toNot(beNil())
//      .to(map(\.type, equal(.modifiedAfter)))
//      .to(map(\.rawValue, equal("modifiedAfter")))
//      .to(map(\.value, equal("2025-07-04")))
//      .to(map(\.rawValue, equal("modifiedAfter|2025-07-04")))
//      .to(map(\.description, equal("Modified After 7/4/2025")))
//      .to(map(\.domain, equal(.modification)))
    }
          
  
  
  @Test(".init - Returns nil for invalid rawValues")
  func test_filteringtag_init_rawvalue_invalid() {
    
    expect(FilteringTag(rawValue: "tag|"))
      .to(beNil(), description: "Test case has empty value component")
    
    expect(FilteringTag(rawValue: "cookie|tag"))
      .to(beNil(), description: "Test case has invald label component")
  }
  
  @Test(".init - Escapes reserved characters")
  func test_filteringtag_init_rawvalue_escape() {
    expect(FilteringTag(rawValue: "tag|cookie:chocolate-chip"))
      .to(equal(.tag("cookie:chocolate-chip")))
      .to(map(\.rawValue, equal("tag")))
      .to(map(\.value, equal("cookie:chocolate-chip")))
    
    expect(FilteringTag(rawValue: "tag|cookie|snickerdoodle"))
      .to(equal(.tag("cookie|snickerdoodle")))
      .to(map(\.rawValue, equal("tag")))
      .to(map(\.value, equal("cookie|snickerdoodle")))
  }
  
  @Test(".rawValue - Returns correct rawValue for queue-type filteringtag")
  func test_filteringtag_rawvalue_queue() {
    expect(bakingQueue)
      .toNot(beNil())
      .to(map(\.type, equal(.queue)))
      .to(map(\.rawValue, equal("queue")))
      .to(map(\.value, equal("Baking TODOs")))
      .to(map(\.rawValue, equal("queue|Baking TODOs")))
      .to(map(\.description, equal("In Queue: Baking TODOs")))
      .to(map(\.domain, equal(.queue)))
  }
  
  @Test("TagType.rawValue - Returns correct rawValue")
  func test_filteringtag_tagtype_rawvalue() {
    expect(FTagType.tag.rawValue)
      .to(equal("tag"))

    expect(FTagType.artist.rawValue)
      .to(equal("artist"))

    expect(FTagType.contributor.rawValue)
      .to(equal("contributor"))

    expect(FTagType.createdOn.rawValue)
      .to(equal("createdOn"))

    expect(FTagType.createdBefore.rawValue)
      .to(equal("createdBefore"))

    expect(FTagType.createdAfter.rawValue)
      .to(equal("createdAfter"))

    expect(FTagType.modifiedOn.rawValue)
      .to(equal("modifiedOn"))

    expect(FTagType.modifiedBefore.rawValue)
      .to(equal("modifiedBefore"))

    expect(FTagType.modifiedAfter.rawValue)
      .to(equal("modifiedAfter"))

    expect(FTagType.queue.rawValue)
      .to(equal("queue"))

  }
  
  @Test("TagType.domain - Returns correct domain")
  func test_filteringtag_tagtype_domain() {
    expect(FilteringTag.TagType.tag.domain).to(equal(.descriptive))
    expect(FilteringTag.TagType.artist.domain).to(equal(.attribution))
    expect(FilteringTag.TagType.contributor.domain).to(equal(.attribution))
  }
  
  @Test("TagType.label - Returns correct label")
  func test_filteringtag_tagtype_label() {
    expect(FilteringTag.TagType.tag.label).to(equal("tag"))
    expect(FilteringTag.TagType.artist.label).to(equal("artist"))
    expect(FilteringTag.TagType.contributor.label).to(equal("contributor"))
  }
  
  @Test("TagType.makeTag(value:) - Creates correct tag")
  func test_filteringtag_maketag() {
    expect(FTagType.tag.makeTag("cookie")).to(equal(cookieTag))
    expect(FTagType.artist.makeTag("cookie")).to(equal(cookieArtist))
    expect(FTagType.contributor.makeTag("cookie")).to(equal(cookieContributor))
  }
}
