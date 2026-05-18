// created on 1/14/25 by robinsr

import Foundation
import Testing
import Nimble
import CustomDump

@testable import HyperTagBrowser


@Suite("Data : FilteringTag", .serialized, .tags(.dataModel))
struct FilteringTagTest {
  
  typealias TagType = FilteringTag.TagType
  typealias Domain = FilteringTag.TagDomain
  
  var usaDay: Date {
    Date(unixTimestamp: 1751612400) // Fri Jul 04 2025 00:00:00 GMT-0700
  }
  
  
  @Suite(".init(rawValue:)")
  struct FilteringTagRawValueTests {
    
    @Test("tag|cookie")
    func test_filteringtag_init_rawvalue_tag() {
      let tag = FilteringTag("tag|cookie")

      expect(tag).toNot(beNil())
      expect(tag.type).to(equal(TagType.tag))
      expect(tag.domain).to(equal(Domain.descriptive))
      expect(tag.value).to(equal("cookie"))
      expect(tag.rawValue).to(equal("tag|cookie"))
      expect(tag.displayString).to(equal("cookie"))
    }
    
    @Test("tag|cookie:chocolate-chip")
    func test_filteringtag_init_rawvalue_semicolon() {
      let tag = FilteringTag("tag|cookie:chocolate-chip")
      
      expect(tag).toNot(beNil())
      expect(tag.type).to(equal(TagType.tag))
      expect(tag.domain).to(equal(Domain.descriptive))
      expect(tag.value).to(equal("cookie:chocolate-chip"))
      expect(tag.rawValue).to(equal("tag|cookie:chocolate-chip"))
      expect(tag.displayString).to(equal("cookie:chocolate-chip"))
    }
    
    @Test("tag|cookie|snickerdoodle")
    func test_filteringtag_init_rawvalue_pipechar() {
      let tag = FilteringTag("tag|cookie|snickerdoodle")
      
      expect(tag).toNot(beNil())
      expect(tag.type).to(equal(TagType.tag))
      expect(tag.domain).to(equal(Domain.descriptive))
      expect(tag.value).to(equal("cookie|snickerdoodle"))
      expect(tag.rawValue).to(equal("tag|cookie|snickerdoodle"))
      expect(tag.displayString).to(equal("cookie|snickerdoodle"))
    }
    
    @Test("creator|cookie")
    func test_filteringtag_init_rawvalue_creator() {
      let tag = FilteringTag("creator|cookie")
      
      expect(tag).toNot(beNil())
      expect(tag.type).to(equal(TagType.creator))
      expect(tag.domain).to(equal(Domain.attribution))
      expect(tag.value).to(equal("cookie"))
      expect(tag.rawValue).to(equal("creator|cookie"))
      expect(tag.displayString).to(equal("Creator: cookie"))
    }
    
    @Test("artist|cookie")
    func test_filteringtag_init_rawvalue_artist() {
      let tag = FilteringTag("artist|cookie")
      
      expect(tag).toNot(beNil())
      expect(tag.type).to(equal(TagType.artist))
      expect(tag.domain).to(equal(Domain.attribution))
      expect(tag.value).to(equal("cookie"))
      expect(tag.rawValue).to(equal("artist|cookie"))
      expect(tag.displayString).to(equal("Artist: cookie"))
    }
    
    @Test("contributor|cookie")
    func test_filteringtag_init_rawvalue_contributor() {
      let tag = FilteringTag("contributor|cookie")
      
      expect(tag).toNot(beNil())
      expect(tag.type).to(equal(TagType.contributor))
      expect(tag.domain).to(equal(Domain.attribution))
      expect(tag.value).to(equal("cookie"))
      expect(tag.rawValue).to(equal("contributor|cookie"))
      expect(tag.displayString).to(equal("Contributor: cookie"))
    }
    
    @Test("queue|Baking TODOs")
    func test_filteringtag_init_rawvalue_queue() {
      let tag = FilteringTag("queue|Baking TODOs")
      
      expect(tag).toNot(beNil())
      expect(tag.type).to(equal(TagType.queue))
      expect(tag.domain).to(equal(Domain.queue))
      expect(tag.value).to(equal("Baking TODOs"))
      expect(tag.rawValue).to(equal("queue|Baking TODOs"))
      expect(tag.displayString).to(equal("In Queue: Baking TODOs"))
    }
    
    @Test("createdOn|2025-07-04")
    func test_filteringtag_init_rawvalue_created_on() {
      let tag = FilteringTag("createdOn|2025-07-04")

      expect(tag).toNot(beNil())
      expect(tag.type).to(equal(TagType.createdOn))
      expect(tag.domain).to(equal(Domain.creation))
      expect(tag.value).to(equal("2025-07-04"))
      expect(tag.rawValue).to(equal("createdOn|2025-07-04"))
      expect(tag.displayString).to(equal("Created On Jul 4, 2025"))
    }
    
    @Test("createdBefore|2025-07-04")
    func test_filteringtag_init_rawvalue_created_before() {
      let tag = FilteringTag("createdBefore|2025-07-04")
      
      expect(tag).toNot(beNil())
      expect(tag.type).to(equal(TagType.createdBefore))
      expect(tag.domain).to(equal(Domain.creation))
      expect(tag.value).to(equal("2025-07-04"))
      expect(tag.rawValue).to(equal("createdBefore|2025-07-04"))
      expect(tag.displayString).to(equal("Created Before Jul 4, 2025"))
    }
    
    @Test("createdAfter|2025-07-04")
    func test_filteringtag_init_rawvalue_created_after() {
      let tag = FilteringTag("createdAfter|2025-07-04")
      
      expect(tag).toNot(beNil())
      expect(tag.type).to(equal(TagType.createdAfter))
      expect(tag.domain).to(equal(Domain.creation))
      expect(tag.value).to(equal("2025-07-04"))
      expect(tag.rawValue).to(equal("createdAfter|2025-07-04"))
      expect(tag.displayString).to(equal("Created After Jul 4, 2025"))
    }
  }
  
  @Suite("TagType")
  struct FilteringTagTagTypeTests {
    
    @Test(".rawValue")
    func test_filteringtag_tagtype_rawvalue() {
      expect(TagType.tag.rawValue)
        .to(equal("tag"))

      expect(TagType.artist.rawValue)
        .to(equal("artist"))

      expect(TagType.contributor.rawValue)
        .to(equal("contributor"))

      expect(TagType.createdOn.rawValue)
        .to(equal("createdOn"))

      expect(TagType.createdBefore.rawValue)
        .to(equal("createdBefore"))

      expect(TagType.createdAfter.rawValue)
        .to(equal("createdAfter"))

      expect(TagType.queue.rawValue)
        .to(equal("queue"))

    }
    
    @Test(".domain")
    func test_filteringtag_tagtype_domain() {
      expect(TagType.tag.domain)
        .to(equal(.descriptive))
      
      expect(TagType.artist.domain)
        .to(equal(.attribution))
      
      expect(TagType.contributor.domain)
        .to(equal(.attribution))
    }
    
    
    @Test(".makeTag(value:)")
    func test_filteringtag_maketag() {
      expect(
        TagType.tag.makeTag("cookie")
      )
      .to(equal(
        FilteringTag("tag|cookie")
      ))
      
      expect(
        TagType.artist.makeTag("cookie")
      )
      .to(equal(
        FilteringTag("artist|cookie")
      ))
      
      expect(
        TagType.contributor.makeTag("cookie")
      )
      .to(equal(
        FilteringTag("contributor|cookie")
      ))
    }

  }
}
