// created on 2/7/25 by robinsr

import Foundation
import RegexBuilder



struct SearchTerm: Identifiable, Hashable {
  typealias Kind = FilteringTag.TagType
  
  let value: String
  let kind: Kind
  let comparison: SearchQuery.ComparisonOperator = .equalTo
  
  var id: String {
    queryString.hashId
  }

  init(value: String, kind: Kind) {
    self.value = value
    self.kind = kind
  }
  
  init(_ str: String) {
    let (value, kind) = Matcher.matchOne(in: str)
    self.init(value: value, kind: kind)
  }
  
  
  /**
   Provides a regex that matches the string forms a SearchTerm can take:
   
    - `#keyword` and `#{keyword with spaces}`
    - `@attribution` and `@{attribution with spaces}` etc
    - `plain_text_word`
    - `{artist:Curly Braces}`
   */
  struct Matcher {
    
    static let filterTypes = FilteringTag.TagType.allCases
    static let filterNames = FilteringTag.TagType.allCases.map(\.rawValue)
    
    static let shortSingle  = /([#@!$~+]{1})([^\s\{\}]+)/
    static let shortMulti   = /([#@!$~+]{1})\{([^\}]+)\}/
    static let fullSingle   = /\{(\w+)\:([^\}]+)\}/
    static let fullMulti    = /\{(\w+)\:([^\}]+)\}/
    static let singleWord   = /(.{0})([^\s]+)/
    static let groupedWords = /(.{0})\{([^\}]+)\}/
    
    static let patterns = [shortSingle, shortMulti, fullSingle, fullMulti, groupedWords, singleWord]

    static func matchOne(in str: String) -> (String, Kind) {
      for pattern in Self.patterns {
        if let match = try? pattern.wholeMatch(in: str) {
          
          let prefixOrKind = String(match.output.1)
          let value = String(match.output.2)
          
          var kind: Kind = .tagType(for: prefixOrKind)
          
          if let longKind = filterTypes.first(where: { $0.rawValue == prefixOrKind }) {
            kind = longKind
          }
          
          return (value, kind)
        }
      }
      
      return (str, .related)
    }
    
    static func matchAll(in str: String) -> [(String, Kind)] {
      var matches: [(String, Kind)] = []
      
      var remainingTerms = str
      
      for pattern in Self.patterns {
        let matchesForPattern = remainingTerms.matches(of: pattern)
        
        for match in matchesForPattern {
          remainingTerms = remainingTerms.replacing(match.output.0, with: "")
          
          let prefixOrKind = String(match.output.1)
          let value = String(match.output.2)
          
          var kind: Kind = .tagType(for: prefixOrKind)
          
          if let longKind = filterTypes.first(where: { $0.rawValue == prefixOrKind }) {
            kind = longKind
          }
          
          matches.append((value, kind))
        }
      }
      
      return matches
    }
  }
}


extension SearchTerm: SearchableContentAttribute {
  var searchPredicate: any SearchQueryFragment {
    SearchQuery.Predicate(
      lhs: kind.fsAttribute,
      rhs: comparison.statementValue(for: value, modifiers: "cd"),
      compare: .contains
    )
  }
}

extension SearchTerm: SearchQueryFragment {
  var nsPredicate: NSPredicate {
    searchPredicate.nsPredicate
  }
  
  /*
   Modifiers
   c - Performs a case-insensitive search.
   d - Performs a search that ignores diacritical marks.
   w - Matches on word boundaries. This modifier treats transitions from lowercase to uppercase as word boundaries.
   t - Performs a search on a tokenized value. For example, a search field can contain tokenized values.
   * - Performs a wildcard search. Match a substring at the beginning, end, or middle.
   \ - Don’t interpret the character that follows. Use this to include special characters. Examples include \’ and \”.
   */
  var queryString: String {
    comparison.statement(for: kind.fsAttribute, value: value, mods: "cd")
  }
}


extension SearchTerm: Filterable {
  var asFilter: FilteringTag {
    self.kind.makeTag(value) ?? FilteringTag.related(value)
  }
}


extension SearchTerm: CustomStringConvertible {
  var description: String {
    asFilter.description
  }
}


extension SearchTerm: RawRepresentable {
  var rawValue: String {
    asFilter.asSearchString
  }
  
  init(rawValue: String) {
    self.init(rawValue)
  }
}
