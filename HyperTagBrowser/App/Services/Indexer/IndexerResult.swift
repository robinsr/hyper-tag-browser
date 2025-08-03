// created on 6/2/25 by robinsr



enum IndexerResult: Identifiable, Sendable, CustomStringConvertible, CustomDebugStringConvertible {
  case success(String, Int)
  case failure(IndexerServiceError)
  
  var id: String {
    switch self {
    case .success(let message, let count):
      return "success:\(message):\(count)".hashId
    case .failure(let error):
      return "failure:\(error.localizedDescription)".hashId
    }
  }

  var description: String {
    switch self {
    case .success(let message, let count):
      return "\(message) (\(count) items processed)"
    case .failure(let error):
      return "\(error.localizedDescription)"
    }
  }
  
  var debugDescription: String {
    switch self {
    case .success(let message, let count):
      return "IndexerResult.success(\(message), \(count))"
    case .failure(let error):
      return "IndexerResult.failure(\(error))"
    }
  }

  var isSuccess: Bool {
    if case .success = self { return true }
    return false
  }
  
  var isFailure: Bool {
    if case .failure = self { return true }
    return false
  }
  
  var error: IndexerServiceError? {
    if case let .failure(error) = self { return error }
    return nil
  }
}
