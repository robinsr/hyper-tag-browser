// created on 12/23/25 by robinsr


extension SearchTerm {
  
  /**
   * **SearchTerm.Matcher** provides the ability to match a string token from
   * user input and
   * Provides a regex that matches the string forms a SearchTerm can take:
   *
   *  - `#keyword` and `#{keyword with spaces}`
   *  - `@attribution` and `@{attribution with spaces}` etc
   *  - `plain_text_word`
   *  - `{artist:Curly Braces}`
   */
  struct Matcher {
    
    static let filterTypes = FilteringTag.TagType.allCases
    static let filterNames = FilteringTag.TagType.allCases.map(\.rawValue)
    
    typealias RegexSubSubSub = Regex<(Substring, Substring, Substring)>
    
    static var shortSingle: RegexSubSubSub {
      /([#@!$~+]{1})([^\s\{\}]+)/
    }
    
    static var shortMulti: RegexSubSubSub {
      /([#@!$~+]{1})\{([^\}]+)\}/
    }
    
    static var fullSingle: RegexSubSubSub {
      /\{(\w+)\:([^\}]+)\}/
    }
    
    static var fullMulti: RegexSubSubSub {
      /\{(\w+)\:([^\}]+)\}/
    }
    
    static var singleWord: RegexSubSubSub {
      /(.{0})([^\s]+)/
    }
    
    static var groupedWords: RegexSubSubSub {
      /(.{0})\{([^\}]+)\}/
    }
    
    static var patterns: [RegexSubSubSub] {
      [shortSingle, shortMulti, fullSingle, fullMulti, groupedWords, singleWord]
    }
    
    
    typealias TokenMatchResult = (String, FilteringTag.TagType)
    
    /**
     * Matches a single user-input token to a `FilteringTag.TagType`, returning
     * a tuple of the matched value and the `TagType`
     */
    static func matchOne(in str: String) -> TokenMatchResult {
      for pattern in Self.patterns {
        if let match = try? pattern.wholeMatch(in: str) {
          
          let prefixOrKind = String(match.output.1)
          let value = String(match.output.2)
          
          var kind: SearchTerm.Kind = .tagType(for: prefixOrKind)
          
          if let longKind = filterTypes.first(where: { $0.rawValue == prefixOrKind }) {
            kind = longKind
          }
          
          return (value, kind)
        }
      }
      
      return (str, .related)
    }
    
    
    /**
     * Attempts to match **as many user-input tokens as possible** within the supplied input string.
     * Matches each token to a `FilteringTag.TagType`, returning a tuple of the matched value
     * and the `TagType` for each token identified
     */
    static func matchAll(in str: String) -> [TokenMatchResult] {
      var matches: [TokenMatchResult] = []
      
      var remainingTerms = str
      
      for pattern in Self.patterns {
        let matchesForPattern = remainingTerms.matches(of: pattern)
        
        for match in matchesForPattern {
          remainingTerms = remainingTerms.replacing(match.output.0, with: "")
          
          let prefixOrKind = String(match.output.1)
          let value = String(match.output.2)
          
          var kind: SearchTerm.Kind = .tagType(for: prefixOrKind)
          
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
