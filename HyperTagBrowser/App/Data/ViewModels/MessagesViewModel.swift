// created on 11/25/25 by robinsr

import Factory
import SwiftUI

@MainActor
@Observable
class MessagesViewModel {
  private let logger = EnvContainer.shared.logger("MessagesViewModel")
  private let messageDurationSeconds: Int = 5
  
  var messageQueue = AppMessageQueue(maxCount: 3)

  var message: AppMessage? {
    self.messageQueue.first
  }
  
  @ObservationIgnored
  private var clearMessagesTimer: Timer?
  
  init() {
    let interval = TimeInterval(messageDurationSeconds)
    clearMessagesTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [self] _ in
      Task { await self.cycleMessages() }
    }
  }
  
  
  func cycleMessages() {
    let oldestMsgTime: Date = .now.subtracting(.second, value: messageDurationSeconds)
    messageQueue.clearMessages(before: oldestMsgTime)
  }
  
  func send(_ message: AppMessage) {
    logger.emit(message.level.loglevel, message.message)

    withAnimation {
      messageQueue.enqueue(message)
    }
  }

  func unsend(_ message: AppMessage) {
    withAnimation {
      messageQueue.dequeue(message)
    }
  }

  func send(_ msg: String) {
    send(AppMessage(msg, .info))
  }

  func send(_ msg: ErrorMsg) {
    send(AppMessage(msg.description, .error))
  }
  
  func send(_ msg: String, _ err: Error) {
    send(AppMessage(msg.description, .error))
  }

  func send(ok msg: String) {
    send(AppMessage(msg, .success))
  }

  func send(ok msgs: [String]) {
    send(AppMessage(msgs.joined(separator: " "), .success))
  }

  func send(reject msg: String) {
    send(AppMessage(msg, .warning))
  }

  func send(reject err: AppViewModelError) {
    send(AppMessage(err.localizedDescription, .warning))
  }

  func send(err msg: String) {
    send(AppMessage(msg, .error))
  }

  func send(_ pattern: String, args: [any CVarArg]) {
    send(AppMessage(pattern, .info, arguments: args))
  }

  func send(ok pattern: String, args: [any CVarArg]) {
    send(AppMessage(pattern, .success, arguments: args))
  }

  func send(err pattern: String, args: [any CVarArg]) {
    send(AppMessage(pattern, .error, arguments: args))
  }
}
