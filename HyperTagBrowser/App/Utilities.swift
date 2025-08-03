import Accelerate.vImage
import AppIntents
import AVFoundation
import AVKit
import Combine
import Defaults
import IdentifiedCollections
import SwiftUI
import System


typealias IdArray = IdentifiedArrayOf
typealias AnyCancellable = Combine.AnyCancellable

//struct DebugFunctionCallers {
//  static func caller(file: String = #file, line: Int = #line, function: String = #function) -> String {
//      return "\(file):\(line) : \(function)"
//  }
//  
//  static func callerURL(file: String = #file) -> URL {
//    URL(string: file)!
//  }
//  
//  static func fmtCaller(_ file: String, _ line: Int, _ function: String) -> String {
//    #if DEBUG
//    let relativePath = file
//      .replacingOccurrences(of: Self.selfURL.filepath.string, with: "")
//      .replacingOccurrences(of: ".swift", with: "")
//      .replacingOccurrences(of: "^\\/", with: "", options: .regularExpression)
//      .replacingOccurrences(of: "\\/", with: ".", options: .regularExpression)
//    #else
//    let relativePath = file
//      .replacingOccurrences(of: Self.selfURL.filepath.string, with: "")
//    #endif
//    
//    let funcName = function.replacingOccurrences(of: "\\(.*$", with: "", options: .regularExpression)
//    
//    return "\(relativePath).\(funcName)():\(line)"
//  }
//  
//  static let packageRootPath = String(
//    URL(fileURLWithPath: #file)
//      .pathComponents
//      .prefix(while: { $0 != "App" })
//      .joined(separator: "/")
//      .dropFirst()
//    )
//  
//  static let selfURL: URL = {
//    return URL(string: Self.packageRootPath)!
//  }()
//}


/// Class for logging excessive blocking on the main thread.
final public class Watchdog: NSObject {
  fileprivate let pingThread: PingThread

  @objc public static let defaultThreshold = 0.4

  /// Convenience initializer that allows you to construct a `WatchDog` object with default behavior.
  /// - parameter threshold: number of seconds that must pass to consider the main thread blocked.
  /// - parameter strictMode: boolean value that stops the execution whenever the threshold is reached.
  @objc public convenience init(threshold: Double = Watchdog.defaultThreshold, strictMode: Bool = false) {
    let message = "👮 Main thread was blocked for " + String(format: "%.2f", threshold) + "s 👮"

    self.init(threshold: threshold) {
      if strictMode {
        fatalError(message)
      } else {
        NSLog("%@", message)
      }
    }
  }

  /// Default initializer that allows you to construct a `WatchDog` object specifying a custom callback.
  /// - parameter threshold: number of seconds that must pass to consider the main thread blocked.
  /// - parameter watchdogFiredCallback: a callback that will be called when the the threshold is reached
  @objc public init(threshold: Double = Watchdog.defaultThreshold, watchdogFiredCallback: @escaping () -> Void) {
    self.pingThread = PingThread(threshold: threshold, handler: watchdogFiredCallback)

    self.pingThread.start()
    super.init()
  }

  deinit {
    pingThread.cancel()
  }
}

private final class PingThread: Thread {
  fileprivate var pingTaskIsRunning: Bool {
    get {
      objc_sync_enter(pingTaskIsRunningLock)
      let result = _pingTaskIsRunning
      objc_sync_exit(pingTaskIsRunningLock)
      return result
    }
    set {
      objc_sync_enter(pingTaskIsRunningLock)
      _pingTaskIsRunning = newValue
      objc_sync_exit(pingTaskIsRunningLock)
    }
  }
  private var _pingTaskIsRunning = false
  private let pingTaskIsRunningLock = NSObject()
  fileprivate var semaphore = DispatchSemaphore(value: 0)
  fileprivate let threshold: Double
  fileprivate let handler: () -> Void

  init(threshold: Double, handler: @escaping () -> Void) {
    self.threshold = threshold
    self.handler = handler
    super.init()
    self.name = "WatchDog"
  }

  override func main() {
    while !isCancelled {
      pingTaskIsRunning = true
      DispatchQueue.main.async {
        self.pingTaskIsRunning = false
        self.semaphore.signal()
      }

      Thread.sleep(forTimeInterval: threshold)
      if pingTaskIsRunning {
        handler()
      }

      _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
  }
}
