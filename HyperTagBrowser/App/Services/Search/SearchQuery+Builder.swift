// created on 2/7/25 by robinsr

extension SearchQuery {
  
  /**
   * A builder for constructing complex search queries.
   */
  class Builder {
    var items: [SearchQueryFragment?] = []
    var operation: PredicateCompoundType = .and

    func with(_ term: SearchQueryFragment) -> Builder {
      self.items = items + [term]
      return self
    }

    func with(_ terms: [SearchQueryFragment]) -> Builder {
      self.items = items + terms
      return self
    }

    func build() -> SearchQuery.Compound {
      SearchQuery.Compound(opr: operation, statements: items)
    }
  }
}
