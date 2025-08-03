// created on 2/18/25 by robinsr

import CustomDump
import Defaults
import Factory
import GRDB
import SwiftUI

@Observable
final class DetailScreenViewModel {

  @ObservationIgnored
  private let logger = EnvContainer.shared.logger("DetailScreenViewModel")
  
  @ObservationIgnored
  @Injected(\Container.thumbnailStore) var thumbnailStore
  
  @ObservationIgnored
  @Injected(\PreferencesContainer.userPreferences) var userPrefs

  var viewSize: CGSize = .init(width: 1024, height: 768)

  private var fittedImage: CGImage = .empty
  private(set) var thumbnail: CGImage = .empty
  private(set) var imagePrimarColors: ImageColorSet = .defaults

  init() {
    Task {
      for await update in Defaults.updates(.imageBuffFactor) {
        self.imageBuffingFactor = update
      }
    }
  }
    
    
  /// The image to use in the view
  var image: CGImage { fittedImage }
  /// Dimensions of the displayed image, which may be scaled down from the original
  var imageDimensions: CGSize {
    CGSize(width: image.width, height: image.height)
  }
  /// Dimensions of the original image file. Large images may be scaled down to fit the view size.
  var originalDimensions: CGSize {
    contentItem?.pixelDimensions ?? .zero
  }
  
  var helpActualSize: String {
    guard Defaults[.devFlags].contains(.views_debug) else { return "Actual Size" }
    
    return "Actual - Applies factor: \(zoomFactorOfOriginal.decimalFormat)"
  }
  
  var helpFitSize: String {
    guard Defaults[.devFlags].contains(.views_debug) else { return "Fit to Window" }
    
    return "Fit - Applies factor: \(zoomFactorToFit.decimalFormat)"
  }
  
  var helpSliderRange: String {
    guard Defaults[.devFlags].contains(.views_debug) else { return "Adjust Zoom Level" }
    
    return "Current Factor: \(totalZoom.decimalFormat)"
  }

  @ObservationIgnored
  private var currentTask: Task<Void, Never>? = nil

  var contentItem: ContentItem? {
    didSet { self.onContentSet() }
  }

  var contentAnimated: Bool {
    contentItem?.contentType.isAnimated ?? false
  }

  var contentPixelSize: CGSize {
    contentItem?.pixelDimensions ?? .zero
  }

  var hasThumbnail: Bool {
    if let content = contentItem {
      return thumbnailStore.hasThumbnail(for: content)
    }
    
    return false
  }

  var imageContentFileURL: URL {
    contentItem?.url ?? Constants.emptyImageURL
  }

  /// The factor by which the image is resized to reduce memory usage.
  var imageBuffingFactor: ImageBuffingFactor {
    get { Defaults[.imageBuffFactor] }
    set {
      Defaults[.imageBuffFactor] = newValue
      self.onContentSet()
    }
  }

  /// A CGSize larger than the view size to which very large images can be resized to to reduce memory usage.
  /// When zooming in, the lower dimensions will be visible, in which case the View can reference the unscaled image.
  var buffedViewSize: CGSize { viewSize * imageBuffingFactor.factor }

  /// Lower bound of image size, without which the image would scale into negative dimensions
  let minImageSize = CGSize(width: 400, height: 300)

  /// The size of the current window with lower bound set
  var boundedViewSize: CGSize {
    viewSize.clamped(min: minImageSize)
  }

  /// The scaling factor of the screen, passed to SwiftUI Image view
  var screenScale: CGFloat { 1.0 }          // NSScreen.main?.backingScaleFactor ?? 2

  public func setContentItem(to item: ContentItem?) {
    if let newItem = item {
      logger.emit(.debug, "Setting content item to \(newItem.id.value.quoted)")
      self.contentItem = newItem
    } else {
      logger.emit(.debug, "Clearing content item")
      self.contentItem = nil
    }
  }

  public func setViewSize(to size: CGSize) {
    guard size != self.viewSize else { return }

    logger.emit(.debug, "Setting view size to \(size)")

    self.viewSize = size

    // Reset zoom when view size changes
    self.resetZoom()
  }

  //
  // MARK: - Zoom API
  //

  /// Transient value for zoom applied by current gesture
  var zoomAction: Double = 0.0
  /// Value of zoom applied minus any in-progress gestures. For subscribing to change events; cannot be set directly.
  var totalZoom: Double = 1.0
  /// Value to lower as lower-bound of slider controls
  let minZoom = ZoomRange.default.minimum
  /// Value to lower as upper-bound of slider controls
  let maxZoom = ZoomRange.default.maximum
  /// Value to apply to the View's `.scaleEffect()` modifier.
  var scaleEffect: Double { zoomAction + totalZoom }
  /// The zoom factor to fit the image within the view size
  var zoomFactorToFit: Double {
    //calculateZoomToFit(size: viewSize.clamped(min: minImageSize), of: image)
    zoomFactorOf(dimensions: viewSize)
  }
  var zoomFactorOfOriginal: Double {
    zoomFactorOf(dimensions: originalDimensions)
  }

  /// Sets the zoom factor directly
  public func setZoom(to val: Double) {
    zoomAction = 0.0
    totalZoom = val.clamped(to: minZoom...maxZoom)
  }

  /// Nudges the zoom factor
  public func setZoomAction(to val: Double) {
    let boundedValue = (totalZoom + val).clamped(to: minZoom...maxZoom)

    zoomAction = boundedValue - totalZoom
  }

  public func increaseZoom() {
    setZoom(to: min(maxZoom, totalZoom + maxZoom / 10))
  }

  public func decreaseZoom() {
    setZoom(to: max(minZoom, totalZoom - maxZoom / 10))
  }

  public func addZoom(_ delta: Double) {
    // Ensure adding the delta does not exceed max or min zoom ammouts
    // by adding it to the current zoom value, applying a clamp
    let proposedZoom = (totalZoom + delta - (zoomAction == 0 ? 0 : 1)).clamped(
      to: minZoom...maxZoom)

    // Subtracting the current zoom level from that leaves the amount of delta that
    // can be applied without exceeding the bounds
    //let remaningAction = proposedZoom - totalZoom
    //zoomAction = remaningAction
    zoomAction = proposedZoom
  }

  /// Called on gesture end to apply the zoom action to the total zoom.
  func acceptZoom() {
    totalZoom = scaleEffect.clamped(to: minZoom...maxZoom)
    zoomAction = .zero
  }

  public func setFittedZoomFactor() {
    totalZoom = zoomFactorToFit  // Ideally this should just be 1.0
    totalDrag = .zero
  }

  public func setActualSizeZoomFactor() {
    totalZoom = zoomFactorOfOriginal
    totalDrag = .zero
  }
  
  public func resetZoom() {
    setFittedZoomFactor()
  }


  //
  // MARK: - Drag API
  //

  /// Transient value for amount of drag applied my current gesture.
  var dragAction: CGSize = .zero
  /// Persistent value for total drag applied to the View.
  var totalDrag: CGSize = .zero
  /// Value to be applied to the View's `offset` modifier.
  public var offsetValue: CGSize { totalDrag }          // totalDrag.adding(dragAction)

  /// Adds transient drag amount to the current drag action.
  public func setTranslation(to translation: CGSize) {
    dragAction = translation
  }

  /// Adds transient drag ammount to total trag. Called when the drag gesture ends.
  public func acceptDrag() {
    totalDrag = totalDrag.adding(dragAction)
    dragAction = .zero
  }

  //
  // MARK: - Fill Mode API
  //

  private(set) var fillMode: ContentMode = .fit

  public func toggleFillMode() {
    fillMode = fillMode.toggle()

    self.resetZoom()          // Reset zoom when toggling fill mode
  }

  //
  // MARK: - Private Methods
  //

  private func onContentSet() {
    logger.emit(.debug, "ContentItem update to \(contentItem?.id.value ?? "nil")")

    self.resetZoom()

    currentTask?.cancel()

    currentTask = Task {
      // Move expensive work to background

      self.fittedImage = await Task.detached(priority: .userInitiated) {
        self.getContentImage(optimizeToViewSize: true)
      }.value

      self.imagePrimarColors = await Task.detached(priority: .userInitiated) {
        self.getImagePrimarColors()
      }.value

//      self.thumbnail = await Task.detached(priority: .background) {
//        self.getContentImageThumnail()
//      }.value
    }
  }

  private func getContentImage(optimizeToViewSize resize: Bool = false) -> CGImage {
    guard let contentURL = contentItem?.url else { return .empty }

    if resize && contentPixelSize.exceeds(buffedViewSize) {
      let adjustedSize = contentPixelSize.scaled(toFit: buffedViewSize)

      return ImageDisplay.sized(adjustedSize, .original).cgImage(url: contentURL) ?? .empty
    } else {
      return ImageDisplay.full.cgImage(url: contentURL) ?? .empty
    }
  }


  private func getImagePrimarColors() -> ImageColorSet {
    guard
      let content = contentItem,
      let thumbnailImg = thumbnailStore.thumbnailImage(for: content)
    else {
      return ImageColorSet.defaults
    }

    return ImageColorSet.fromImage(thumbnailImg)
  }

  private func calculateZoomToFit(size: CGSize) -> Double {
    calculateZoomToFit(size: size, of: self.image)
  }

  private func calculateZoomToFit(size: CGSize, of image: CGImage) -> Double {
    let scaleX = Double(image.width) / size.width
    let scaleY = Double(image.height) / size.height

    return max(scaleX, scaleY)
  }
  
  
  /// Returns the zoom factor needed to show an image with the given dimensions at full
  /// size within the current view size (application window size)
  private func zoomFactorOf(dimensions size: CGSize) -> Double {
    let scaleX = Double(size.width) / viewSize.width
    let scaleY = Double(size.height) / viewSize.height

    return max(scaleX, scaleY)
  }

  struct ZoomRange {
    let minimum: Double
    let maximum: Double

    static let `default` = ZoomRange(minimum: 0.2, maximum: 3.0)
  }
}

extension ContentMode {

  var icon: SymbolIcon {
    switch self {
      case .fit: return .fillModeOut
      case .fill: return .fillModeIn
      // In case of future additions, default to fit mode icon
      @unknown default: return .fillModeOut
    }
  }

  var usesTransparentToolbar: Bool {
    switch self {
      case .fit: return false
      case .fill: return true
      @unknown default: return false
    }
  }

  func toggle() -> ContentMode {
    switch self {
      case .fit: return .fill
      case .fill: return .fit
      @unknown default:
        // In case of future additions, default to fit mode
        return .fit
    }
  }
}


enum ImageBuffingFactor: String, Hashable, CaseIterable, SelectableOptions, CustomStringConvertible {
  case high, medium, low, none

  var factor: Double {
    switch self {
      case .high: return 1.15
      case .medium: return 2.00
      case .low: return 3.00
      case .none: return .infinity
    }
  }
  
  var description: String {
    self.rawValue.capitalized
  }
  
  static var asSelectables: [SelectOption<ImageBuffingFactor>] {
    return Self.allCases.map { SelectOption(value: $0, label: $0.description) }
  }
}

extension ImageBuffingFactor: Defaults.Serializable {
  public static var defaultValue: ImageBuffingFactor { .high }
}
