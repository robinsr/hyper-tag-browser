// Created on 9/7/24 by robinsr

import Cache
import DebouncedOnChange
import Defaults
import Factory
import Foundation
import GRDBQuery
import SwiftUI
import os



struct ThumbnailView: View {
  let logger = EnvContainer.shared.logger("ThumbnailView")

  @Injected(\Container.thumbnailStore) var thumbnailStore

  let content: ContentItem

  @State var tileSize: CGSize
  @State var image: CGImage? = nil

  var thumbnailSrc: CGImage {
    // Uses the image stored in State first, if State is nill then make a request from the thumbnail store
    // (which will schedule an asynchronous fetch if currently not available), then finally default to an empty image.
    image ?? thumbnailStore.thumbnailImage(for: content) ?? .empty
  }

  var thumbnailType: ThumbnailType {
    FirstTrueBuilder.withDefault(ThumbnailType.icon) {
      (thumbnailSrc == .empty, .icon)
      (content.conforms(to: .folder), .icon)
      (content.diverges(from: .folder), .thumbnail)
    }
  }
  
  enum ThumbnailUpdaterMethod {
    /// Observe the thumbnail store for changes to keys
    case observeKeys
    /// Just check the thumbnail store every so often
    case interval
  }
  
  let thumbnailUpdaterMethod: ThumbnailUpdaterMethod = .interval

  var body: some View {
    ZStack(alignment: .center) {
      ImagePlaceholder(inset: 16)
        .visible(thumbnailSrc == .empty)

      Group {
        switch thumbnailType {
          case .icon:
            IconThumbnail
          default:
            SimpleResizableThumbnailView(cgImage: thumbnailSrc)
              .shadow(radius: 4, x: 0, y: 0)
        }
      }
      .hidden(thumbnailSrc == .empty)
    }
    .aspectRatio(1, contentMode: .fill)
    .obscureContents(enabled: .constant(false))
    .environment(\.releventContentType, content.contentType)
    .modify(when: content.conforms(to: .folder)) { view in
      view.overlay(alignment: .bottom) {
        ThumbnailText
      }
    }
    .modify(when: thumbnailUpdaterMethod == .interval) { $0
      .onAppear(perform: setupIntervalThumbnailUpdate)
    }
    .modify(when: thumbnailUpdaterMethod == .observeKeys) { $0
      .onChange(
        of: thumbnailStore.keys,
        initial: true,
        debounceTime: .milliseconds(500),
        debouncer: $thumbnailDebouncer) {
          checkThumbnailStore()
        }
    }
  }
  
  @State var thumbnailDebouncer = Debouncer()
  
  @State var thumbnailCheckTimer: AnyCancellable? = nil
  
  func setupIntervalThumbnailUpdate() {
    guard image == nil else { return }
    
    thumbnailCheckTimer = Timer.publish(every: 1.0, on: .main, in: .common)
      .autoconnect()
      .sink { _ in
        if thumbnailStore.hasThumbnail(for: content) {
          if let cachedImage = thumbnailStore.thumbnailImage(for: content) {
            image = cachedImage
            
            thumbnailCheckTimer?.cancel()
          }
        }
      }
  }
  
  func checkThumbnailStore() {
    guard image == nil else { return }
    
    if thumbnailStore.keys.contains(content.id) {
      if let cachedImage = thumbnailStore.thumbnailImage(for: content) {
        image = cachedImage
      }
    }
  }

  var ThumbnailText: some View {
    Text(content.name)
      .truncationMode(.tail)
      .lineLimit(1)
      .padding(.bottom, 10)
  }

  var IconThumbnail: some View {
    Image(decorative: thumbnailSrc, scale: 1.0, orientation: .up)
      .renderingMode(.original)
      .resizable()
      .aspectRatio(1, contentMode: .fill)
      .minimumSize(width: 0, height: 0, alignment: .center)
      .padding(20)
      .clipped()
  }
}
