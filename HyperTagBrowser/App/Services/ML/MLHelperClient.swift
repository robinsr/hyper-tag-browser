// created on 8/13/25 by robinsr

import Factory
import Foundation


/**
 * Minimal, robust client for the ml-helper sidecar that:
 *
 * - Launches once; keeps it alive
 * - NDJSON over stdin/stdout
 * - Routes responses by "id"
 */
//final class MLHelperClient {
//
//  private let logger = EnvContainer.shared.logger("MLHelperClient")
//
//  private var process: Process?
//  private let stdinPipe = Pipe()
//  private let stdoutPipe = Pipe()
//  private let ioQueue = DispatchQueue(label: "ml-helper.io")
//  private let framer = NDJSONFramer()
//  private let decoder = JSONDecoder()
//  private let encoder = JSONEncoder()
//
//  /// pending[id] -> completion(Result<Data,Error>)
//  private var pending = [String: (Result<Data, Error>) -> Void]()
//  private let lock = NSLock()
//  private var sawEOF = false
//
//  // MARK: Public
//
//  func startIfNeeded() throws {
//    if process != nil && !sawEOF { return }
//    let url = try resolveHelperURL()
//    let p = Process()
//    p.executableURL = url
//    p.standardInput = stdinPipe
//    p.standardOutput = stdoutPipe
//    p.standardError = FileHandle.standardError
//    p.terminationHandler = { [weak self] _ in
//      self?.sawEOF = true
//      self?.logger.emit(.error, "ml-helper terminated")
//      self?.failAllInFlight(
//        error: NSError(
//          domain: "MLHelper", code: 1001,
//          userInfo: [NSLocalizedDescriptionKey: "helper terminated"]))
//      self?.process = nil
//    }
//    try p.run()
//    process = p
//    sawEOF = false
//    startReadingStdout()
//    logger.emit(.info, "ml-helper launched at \(url.path)")
//  }
//
//  func stop() {
//    process?.terminate()
//    process = nil
//  }
//
//  /// Sends a request struct that conforms to MLRequest and returns the raw JSON line of the response.
//  func send<R: MLRequest>(request: R, timeout: TimeInterval = 10.0) async throws -> Data {
//    try startIfNeeded()
//    let id = request.id
//    let data = try encoder.encode(request)
//    let line = data + Data([0x0A])
//
//    return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Data, Error>) in
//      register(id: id, timeout: timeout, cont: cont)
//      
//      ioQueue.async { [weak self] in
//        do {
//          try self?.stdinPipe.fileHandleForWriting.write(contentsOf: line)
//        } catch {
//          self?.complete(id: id, result: .failure(error))
//        }
//      }
//    }
//  }
//
//  /// Convenience: send + decode into target Decodable
//  func sendDecoding<T: Decodable, R: MLRequest>(
//    _ responseType: T.Type, request: R, timeout: TimeInterval = 10.0
//  ) async throws -> T {
//    let data = try await send(request: request, timeout: timeout)
//    return try decoder.decode(T.self, from: data)
//  }
//
//  // MARK: Convenience commands
//
//  func ping() async throws -> PingResponse {
//    try await sendDecoding(PingResponse.self, request: PingRequest())
//  }
//
//  func embedImage(path: String) async throws -> EmbedImageResponse {
//    try await sendDecoding(EmbedImageResponse.self, request: EmbedImageRequest(path: path))
//  }
//
//  func suggestTags(fileEmbedding: [Float], tagEmbeddings: [(String, [Float])]) async throws
//    -> SuggestTagsResponse
//  {
//    try await sendDecoding(
//      SuggestTagsResponse.self,
//      request: SuggestTagsRequest(fileEmbedding: fileEmbedding, tagEmbeddings: tagEmbeddings))
//  }
//
//  // MARK: Stdout handling
//
//  private func startReadingStdout() {
//    stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] h in
//      guard let self else { return }
//      let chunk = h.availableData
//      if chunk.isEmpty {
//        self.sawEOF = true
//        return
//      }
//      for line in self.framer.push(chunk) {
//        guard let id = self.peekID(in: line) else {
//          self.logger.emit(.warning, "Received NDJSON without id")
//          continue
//        }
//        self.complete(id: id, result: .success(line))
//      }
//    }
//  }
//
//  private func peekID(in line: Data) -> String? {
//    // Fast path: scan for "id":"..."; we avoid JSON parse here
//    guard let s = String(data: line, encoding: .utf8) else { return nil }
//    guard let idRange = s.range(of: #""id"\s*:\s*"#, options: .regularExpression) else {
//      return nil
//    }
//    let rest = s[idRange.upperBound...]
//    guard let q1 = rest.firstIndex(of: "\"") else { return nil }
//    let after = rest.index(after: q1)
//    guard let q2 = rest[after...].firstIndex(of: "\"") else { return nil }
//    return String(rest[after..<q2])
//  }
//
//  // MARK: Pending bookkeeping
//
//  private func register(id: String, timeout: TimeInterval, cont: CheckedContinuation<Data, Error>) {
//    lock.lock()
//    defer { lock.unlock() }
//    pending[id] = { result in
//      switch result {
//        case .success(let data): cont.resume(returning: data)
//        case .failure(let err): cont.resume(throwing: err)
//      }
//    }
//    ioQueue.asyncAfter(deadline: .now() + timeout) { [weak self] in
//      self?.complete(
//        id: id,
//        result: .failure(
//          NSError(
//            domain: "MLHelper", code: 1000,
//            userInfo: [NSLocalizedDescriptionKey: "timeout for \(id)"])))
//    }
//  }
//
//  private func complete(id: String, result: Result<Data, Error>) {
//    lock.lock()
//    let cb = pending.removeValue(forKey: id)
//    lock.unlock()
//    cb?(result)
//  }
//
//  private func failAllInFlight(error: Error) {
//    lock.lock()
//    let all = pending
//    pending.removeAll()
//    lock.unlock()
//    for (_, cb) in all { cb(.failure(error)) }
//  }
//}
