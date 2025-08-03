// created on 4/2/25 by robinsr

import SwiftUI
import UniformTypeIdentifiers



struct FileTypeIcon: RawRepresentable, AppIcon {
  var rawValue: String
  var helpText: String? = nil
  var size: CGFloat
  var fileType: UTType
  var nsImage: NSImage
  
  /* Conforming to `RawRepresentable` */
  init(rawValue: String) {
    self.init(uttype: UTType(rawValue) ?? .item, size: 12)
  }
  
  init(uttype: UTType, size: CGFloat = 36) {
    self.rawValue = uttype.identifier
    self.fileType = uttype
    self.size = size
    self.nsImage = NSWorkspace.shared.icon(for: uttype).resize(to: .init(width: size, height: size))
  }
  
  var id: String { self.rawValue }

  var asImage: Image {
    Image(nsImage: nsImage)
      .renderingMode(.template)
  }
  
  var asIcon: some View {
    Image(nsImage: nsImage)
      .renderingMode(.template)
      .frame(width: size, height: size)
  }
  
  func resized(to size: CGFloat) -> Self {
    FileTypeIcon(uttype: fileType, size: size)
  }
  
  static let folder = FileTypeIcon(uttype: .folder, size: 12)
  
  static let systemIconMap: [UTType: String] = [
    .folder: "folder",
    .application: "app",
    .pdf: "pdf",
    .image: "photo",
    .audio: "music.note",
    .video: "film",
    .text: "doc.text",
    .zip: "archivebox",
  ]
  
  var systemName: String {
    Self.systemIconMap.first(where: { fileType.conforms(to: $0.key) })?.value ?? "doc"
  }
}

