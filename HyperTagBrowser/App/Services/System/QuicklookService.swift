// created on 9/16/24 by robinsr

import AppKit
import Cache
import Combine
import Defaults
import Factory
@preconcurrency import QuickLookThumbnailing


typealias ThumbnailType = QLThumbnailRepresentation.RepresentationType
typealias ThumbnailRequestType = QLThumbnailGenerator.Request.RepresentationTypes
typealias QLRequest = QLThumbnailGenerator.Request

extension ThumbnailType: Codable {}


/**
 Service for generating thumbnails for files
 */
actor QuicklookService {
  static let shared = QuicklookService()
  
  private let logger = EnvContainer.shared.logger("QuicklookService")
  private let fs = Container.shared.fileService()
  private let timer = Container.shared.timer()
  private let generator = QLThumbnailGenerator.shared
  
  let store: Storage<String, QLResult>
  
  init() {
    let diskConfig = DiskConfig(name: "tfg-qlthumb-chache", expiry: .seconds(1200))
    let memoryConfig = MemoryConfig(expiry: .seconds(100), countLimit: 10, totalCostLimit: 10)
    
    self.store = try! Storage(
      diskConfig: diskConfig,
      memoryConfig: memoryConfig,
      fileManager: FileManager.default,
      transformer: TransformerFactory.forCodable(ofType: QLResult.self)
    )
  }
  
  private var screenScale: CGFloat {
    NSScreen.main?.backingScaleFactor ?? 2
  }
  
  private func request(_ url: URL, _ size: CGSize, _ types: ThumbnailRequestType = .thumbnail) -> QLRequest {
    //let roundedSize = size.scaled(byFactor: 0.8).rounded(.toNearestOrEven)
    let roundedSize = size.rounded(.toNearestOrEven)
    
    let qlReq = QLRequest(
      fileAt: url,
      size: roundedSize,
      scale: screenScale,
      representationTypes: types)
    
    qlReq.minimumDimension = size.longestSide
    
    return qlReq
  }
  
  private func cacheKey(_ url: URL, _ size: CGSize, _ type: ThumbnailType) -> String {
    "\(url.filepath.string)/\(size.longestSide)/\(type)"
  }
  
  private func retrieveCached(_ key: String) -> QLResult? {
    try? store.object(forKey: key)
  }
  
  private func insertCached(_ key: String, _ value: QLResult) -> QLResult {
    try? store.setObject(value, forKey: key)
    
    return value
  }
  
  func imageToBlob(nsImage: NSImage) -> Data {
    let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
    return NSBitmapImageRep(cgImage: cgImage!).representation(using: .png, properties: [:])!
  }
  
  func blob(fileUrl: URL, size: CGSize) async -> QLResult {
    await bestRepresentation(for: fileUrl, size: size)
  }
  
  /**
   Returns a resized icon for the file at the given url
   */
  func icon(fileURL url: URL, size: CGSize) -> QLResult {
    let cachekey = cacheKey(url, size, .icon)
    
    if let cached = retrieveCached(cachekey) {
      return cached
    }
    
    // "The returned image has an initial size of 32 pixels by 32 pixels"
    let icon = NSWorkspace.shared.icon(forFile: url.path).resize(to: size)
    
    return QLResult(icon, .icon)
  }
  
  
  /**
   Fetches a uncached thumbnail for a file, returning either a thumbnail or icon depdening on the file type
   */
  func bestRepresentation(for url: URL, size: CGSize) async -> QLResult {
      // TODO: This will ignore any custom icons set by the user
    if url.isDirectory {
      return icon(fileURL: url, size: size)
    }

    do {
      let representation = try await generator.generateBestRepresentation(for: request(url, size))

      return QLResult(representation)
    } catch {
      logger.emit(.error, ErrorMsg("Failed to generate thumbnail for \(url.path); \(error.legibleDescription)", error))
      
      return icon(fileURL: url, size: size)
    }
  }
  
  
  /**
   Fetches a uncached thumbnail for a file, returning either a thumbnail or icon depdening on the file type
   */
  func generateRepresentations(for url: URL, size: CGSize) async throws -> QLResult {
    
    let key = cacheKey(url, size, .thumbnail)
    
    if let cached = retrieveCached(key) {
      return cached
    }
    
    guard fs.exists(at: url) else {
      throw QuicklookServiceError.noSuchFile(url)
    }
    
    if url.isDirectory {
      return icon(fileURL: url, size: size)
    }
    
    return try await withCheckedThrowingContinuation { cont in
      generator.generateRepresentations(for: request(url, size, .thumbnail)) { rep, type, err in
        if let error = err {
          return cont.resume(throwing: QuicklookServiceError.quicklookError(error))
        }
        
        guard let generationResult = rep else {
          return cont.resume(throwing: QuicklookServiceError.noRepresentation(url))
        }
        
        let result = self.insertCached(key, QLResult(generationResult))
        
        cont.resume(returning: result)
      }
    }
  }
  
  
  /**
   * A Sendable wrapper struct for resulting thumbnail data. Support for Swift Concurrency
   */
  struct QLResult: Codable, Sendable {
    let imageData: Data
    let type: ThumbnailType
    
    init(_ rep: QLThumbnailRepresentation) {
      self.imageData = rep.nsImage.tiffRepresentation ?? Data()
      self.type = rep.type
    }
    
    init(_ image: NSImage, _ type: ThumbnailType) {
      self.imageData = image.tiffRepresentation ?? Data()
      self.type = type
    }
    
    var isEmpty: Bool {
      imageData.isEmpty
    }
    
    var image: NSImage {
      NSImage(data: imageData) ?? NSImage.empty
    }
  }
}


enum QuicklookServiceError: Error {
  case quicklookError(Error)
  case noRepresentation(URL)
  case noSuchFile(URL)
  
  var description: String {
    switch self {
      case .quicklookError(let error):
        return "Quicklook error: \(error.legibleDescription)"
    case .noRepresentation(let path):
        return "No representation found for \(path.filepath)"
    case .noSuchFile(let path):
        return "No such file at \(path.filepath)"
    }
  }
}
