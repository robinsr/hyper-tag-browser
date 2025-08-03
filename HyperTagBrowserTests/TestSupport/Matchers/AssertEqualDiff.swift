// created on 12/15/24 by robinsr

import Nimble
import Difference

public func equalDiff<T: Equatable>(
  _ expectedValue: T?
) -> Matcher<T> {
  return Matcher.define { actualExpression, msg in
    
    let receivedValue = try actualExpression.evaluate()
    
    var message: ExpectationMessage
    
    
    if receivedValue == nil {
      message = msg.appendedBeNilHint()
      
      if let expectedValue = expectedValue {
        message = ExpectationMessage.expectedCustomValueTo("equal <\(expectedValue)>", actual: "nil")
      }
      
      return MatcherResult(status: .fail, message: message)
    }
    
    if expectedValue == nil {
      return MatcherResult(status: .fail, message: msg.appendedBeNilHint())
    }
    
    let isMatching = receivedValue == expectedValue
    
    if isMatching {
      return MatcherResult(bool: true, message: msg.appended(message: "equal <\(String(describing: expectedValue))>"))
    }
    
    let diffResult = diff(
      expectedValue,
      receivedValue,
      indentationType: .tab,
      skipPrintingOnDiffCount: false,
      nameLabels: .comparing
    )
    
    let diffMsg = diffResult.joined(separator: ", ")
    
    return MatcherResult(bool: isMatching, message: msg.appended(details: diffMsg))
  }
}
