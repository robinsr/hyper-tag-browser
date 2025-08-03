// created on 6/2/25 by robinsr

@resultBuilder
struct FirstTrueBuilder<Value> {
  static func buildBlock(_ components: (Bool, Value)?...) -> Value? {
    for component in components {
      if let (condition, value) = component, condition {
        return value
      }
    }
    return nil
  }

  static func buildExpression(_ expression: (Bool, Value)) -> (Bool, Value)? {
    return expression
  }

  static func buildOptional(_ component: Value?) -> Value? {
    return component
  }

  static func buildEither(first component: (Bool, Value)) -> (Bool, Value)? {
    return component
  }

  //
  // MARK: - Convenience Builders
  //

  /**
   * Resolves the first true component from the builder, or `nil` if none are true.
   */
  static func resolve(_ components: (Bool, Value)?) -> Value? {
    return components?.1
  }

  /**
   * Resolves the first true component from the builder, or the default value if none are true.
   */
  static func withDefault(_ defaultValue: Value, @FirstTrueBuilder<Value> _ content: () -> Value?)
    -> Value
  {
    return content() ?? defaultValue
  }
}
