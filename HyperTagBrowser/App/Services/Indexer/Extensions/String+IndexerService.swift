  // created on 3/4/25 by robinsr

  import EnumOptionSet
  import Foundation


  @EnumOptionSet
  enum SqlLikeWildcard {
    case matchBefore
    case matchAfter
  }

  typealias SqlLikeWildcardOptions = SqlLikeWildcard.Set
  extension SqlLikeWildcardOptions {
    
    static let noWildcards: SqlLikeWildcardOptions = []
    static let matchEither: SqlLikeWildcardOptions = [.matchBefore, .matchAfter]
    
    
    func formatForTerm(_ term: String) -> String {
      let prefix = contains(.matchBefore) ? "%" : ""
      let suffix = contains(.matchAfter) ? "%" : ""

      return "\(prefix)\(term)\(suffix)"
    }
  }


  struct SqlLikeValue: ExpressibleByStringLiteral, ExpressibleByStringInterpolation, RawRepresentable {
    var rawValue: String
    var wildcards: SqlLikeWildcard.Set = []
    
    init(_ term: String, affixes: SqlLikeWildcard.Set = []) {
      self.rawValue = term
      self.wildcards = affixes
    }
    
    var value: String {
      wildcards.formatForTerm(rawValue)
    }
    
    init(rawValue value: String) {
      self.init(stringLiteral: value)
    }
    
    init(stringLiteral value: String) {
      self.rawValue = value
      self.wildcards = []
      
      
      if self.value.hasPrefix("%") {
        self.wildcards.insert(.matchBefore)
      }
      
      if self.value.hasSuffix("%") {
        self.wildcards.insert(.matchBefore)
      }
    }
  }


  extension String {
    func asSqlLikeString(_ wilds: SqlLikeWildcard.Set = .matchEither) -> Self {
      wilds.formatForTerm(self)
    }
    
    func subSqlWildcards(for regex: some RegexComponent) -> Self {
      self.replacing(regex, with: "%")
    }
  }


  extension String.StringInterpolation {
    mutating func appendInterpolation(like value: Any, affixes: SqlLikeWildcard.Set = .noWildcards) {
      return appendLiteral(affixes.formatForTerm("\(value)"))
    }
  }
