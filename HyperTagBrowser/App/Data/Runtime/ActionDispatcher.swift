// created on 5/3/25 by robinsr

//struct AsyncActionDispatcher<T> {
//  private var continuation: AsyncStream<T>.Continuation!
//  var stream: AsyncStream<T>
//  
//  init() {
//    self.stream = AsyncStream { continuation in
//      self.continuation = continuation
//    }
//  }
//  
//  func dispatch(_ value: T) {
//    continuation.yield(value)
//  }
//}
