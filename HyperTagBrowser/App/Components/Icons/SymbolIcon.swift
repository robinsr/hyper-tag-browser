// created on 4/2/25 by robinsr

import SwiftUI


struct SymbolIcon: RawRepresentable, CaseIterable, Identifiable, Equatable, AppIcon {
  var systemName: String
  var helpText: String?
  
  var rawValue: String { self.systemName }
  
  /* Conforming to `RawRepresentable` */
  init(rawValue: String) {
    self.systemName = rawValue
  }
  
  init(_ systemName: String, _ helpText: String? = nil) {
    self.systemName = systemName
    self.helpText = helpText
  }
  
  var id: String { String(describing: self) }
  
  /// A SymbolIcon used to represent "empty" or nil
  static let noIcon         = SymbolIcon("square")
  
  static let back           = SymbolIcon("chevron.backward", "Go back")
  static let bookmark       = SymbolIcon("bookmark")
  static let calendar       = SymbolIcon("calendar")
  static let camera         = SymbolIcon("camera")
  static let changeSort     = SymbolIcon("arrow.up.and.down.text.horizontal", "Change sort by")
  static let close          = SymbolIcon("xmark", "Close")
  static let commandKey     = SymbolIcon("command", "Keyboard shortcut")
  static let confirm        = SymbolIcon("checkmark.circle.fill")
  static let copy           = SymbolIcon("doc.on.doc")
  static let database       = SymbolIcon("cylinder.split.1x2")
  static let delete         = SymbolIcon("minus.circle")
  static let editText       = SymbolIcon("rectangle.and.pencil.and.ellipsis")
  static let ellipsis       = SymbolIcon("ellipsis")
  static let emptyThumbnail = SymbolIcon("square.dashed", "No thumbnail available")
  static let error          = SymbolIcon("light.beacon.max")
  static let eyeslash       = SymbolIcon("eye.slash")
  static let expand         = SymbolIcon("arrow.down.left.and.arrow.up.right.square", "Expand")
  static let fillMode       = SymbolIcon("arrow.up.left.and.arrow.down.right.circle.fill", "Change Fill Mode")
  static let fillModeIn     = SymbolIcon("arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill", "Content Fit")
  static let fillModeOut    = SymbolIcon("arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill", "Content Fill")
  static let filterOn       = SymbolIcon("mail.and.text.magnifyingglass")
  static let folder         = SymbolIcon("folder", "Open folder")
  static let forward        = SymbolIcon("chevron.forward", "Go forward")
  static let gear           = SymbolIcon("gearshape")
  static let goUpDirectory  = SymbolIcon("chevron.up", "Go to parent folder")
  static let gridLarge      = SymbolIcon("square.grid.2x2", "Increase tile size")
  static let gridSmall      = SymbolIcon("square.grid.4x3.fill", "Decrease tile size")
  static let home           = SymbolIcon("house")
  static let info           = SymbolIcon("info", "Show info")
  static let insertText     = SymbolIcon("text.insert")
  static let itemChecked    = SymbolIcon("checkmark.circle")
  static let itemCrossed    = SymbolIcon("slash.circle")
  static let linkTo         = SymbolIcon("arrow.turn.up.right", "See details")
  static let lgtm           = SymbolIcon("hand.thumbsup")
  static let listItems      = SymbolIcon("list.bullet")
  static let moon           = SymbolIcon("moon")
  static let newDoc         = SymbolIcon("square.and.pencil")
  static let noFolder       = SymbolIcon("questionmark.folder", "Folder not found")
  static let noThumbnail    = SymbolIcon("questionmark.app.dashed", "No thumbnail available")
  static let ok             = SymbolIcon("checkmark")
  static let paste          = SymbolIcon("arrow.right.doc.on.clipboard")
  static let person         = SymbolIcon("person")
  static let photos         = SymbolIcon("photo.fill.on.rectangle.fill")
  static let queue          = SymbolIcon("checklist")
  static let queueAlt       = SymbolIcon("list.bullet.clipboard.fill")
  static let reloadFiles    = SymbolIcon("arrow.counterclockwise", "Reload files")
  static let search         = SymbolIcon("magnifyingglass", "Search Vault")
  static let keyShortcut    = SymbolIcon("keyboard.command", "Keyboard shortcut")
  static let shrink         = SymbolIcon("arrow.up.right.and.arrow.down.left.square", "Shrink")
  static let sidebar        = SymbolIcon("sidebar.leading", "Toogle Sidebar")
  static let stackedItems   = SymbolIcon("square.grid.3x1.fill.below.line.grid.1x2", "Stacked items")
  static let subcontents    = SymbolIcon("app.connected.to.app.below.fill", "Include sub-directory contents")
  static let subcontentsAlt = SymbolIcon("water.waves.and.arrow.down", "Include sub-directory contents")
  static let success        = SymbolIcon("trophy")
  static let sun            = SymbolIcon("sun.max")
  static let tag            = SymbolIcon("tag", "Edit item's tags")
  static let trash          = SymbolIcon("trash")
  static let triangleLeft   = SymbolIcon("arrowtriangle.left.fill")
  static let triangleRight  = SymbolIcon("arrowtriangle.right.fill")
  static let unknown        = SymbolIcon("questionmark")
  static let volume         = SymbolIcon("externaldrive.fill")
  static let volumeErr      = SymbolIcon("externaldrive.fill.badge.xmark")
  static let warning        = SymbolIcon("exclamationmark")
  static let zoomActual     = SymbolIcon("1.magnifyingglass", "Actual Size")
  static let zoomFitted     = SymbolIcon("arrow.up.left.and.down.right.magnifyingglass", "Zoom to Fit")
  static let zoomIn         = SymbolIcon("plus.magnifyingglass", "Zoom in")
  static let zoomOut        = SymbolIcon("minus.magnifyingglass", "Zoom out")
  
  static var allCases: [SymbolIcon] {
    [
      .back,
      .bookmark,
      .calendar,
      .camera,
      .changeSort,
      .close,
      .commandKey,
      .confirm,
      .copy,
      .database,
      .delete,
      .editText,
      .ellipsis,
      .emptyThumbnail,
      .error,
      .eyeslash,
      .expand,
      .fillMode,
      .fillModeIn,
      .fillModeOut,
      .filterOn,
      .folder,
      .forward,
      .gear,
      .goUpDirectory,
      .gridLarge,
      .gridSmall,
      .home,
      .info,
      .insertText,
      .itemChecked,
      .itemCrossed,
      .keyShortcut,
      .linkTo,
      .lgtm,
      .listItems,
      .moon,
      .newDoc,
      .noFolder,
      .noThumbnail,
      .ok,
      .paste,
      .person,
      .photos,
      .queue,
      .queueAlt,
      .reloadFiles,
      .search,
      .shrink,
      .sidebar,
      .stackedItems,
      .subcontents,
      .subcontentsAlt,
      .success,
      .sun,
      .tag,
      .trash,
      .triangleLeft,
      .triangleRight,
      .unknown,
      .volume,
      .volumeErr,
      .warning,
      .zoomActual,
      .zoomFitted,
      .zoomIn,
      .zoomOut,
    ]
  }
  
  // TODO: Figure out how to access the value when it is set using the `.symbolVariant()` modifier.
  func variant(_ variant: SymbolVariants) -> SymbolIcon {
    SymbolIcon(rawValue: rawValue + "." + variant.asModString)
  }
  
  static func toggle(between opts: (SymbolIcon, SymbolIcon), when state: Bool) -> SymbolIcon {
    return state ? opts.0 : opts.1
  }
}
