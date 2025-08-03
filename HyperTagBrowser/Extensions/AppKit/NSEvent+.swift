// created on 2/18/25 by robinsr

import AppKit
import CustomDump

extension NSEvent {

  /**
   * Returns true when event `deviceID` is `0`, indicating an external mouse device.
   */
  func isExternalMouseDevice() -> Bool {
    return self.deviceID == 0
  }

  /**
   * Returns true when event `deviceID` is not `0`, indicating a trackpad device.
   */
  func isTrackpadDevice() -> Bool {
    return self.deviceID != 0
  }
  
  
  var verticalScrollDelta: CGFloat { self.scrollingDeltaY }
  var horizontalScrollDelta: CGFloat { self.scrollingDeltaX }
  
  /**
   * A CGSize with width and height values matching the X and Y scrolling deltas of the event.
   */
  var scrollDeltaSize: CGSize {
    CGSize(width: horizontalScrollDelta, height: verticalScrollDelta)
  }
}

extension NSEvent: @retroactive CustomDumpStringConvertible {
  public var customDumpDescription: String {
    let type = self.type.description
    let subtype = self.subtype.description
    let phase = self.phase.description
    let location = "(\(self.locationInWindow.x), \(self.locationInWindow.y))"
    let deviceID = self.deviceID

    return """
    NSEvent(type: \(type):\(subtype), phase: \(phase), location: \(location), deviceID: \(deviceID))
    """
  }
}

extension NSEvent.EventType: @retroactive CustomStringConvertible {
  public var description: String {
    switch self {
      case .leftMouseDown: "leftMouseDown"
      case .leftMouseDragged: "leftMouseDragged"
      case .leftMouseUp: "leftMouseUp"
      case .rightMouseDown: "rightMouseDown"
      case .rightMouseUp: "rightMouseUp"
      case .rightMouseDragged: "rightMouseDragged"
      case .otherMouseDown: "otherMouseDown"
      case .otherMouseDragged: "otherMouseDragged"
      case .otherMouseUp: "otherMouseUp"
      case .mouseMoved: "mouseMoved"
      case .mouseEntered: "mouseEntered"
      case .mouseExited: "mouseExited"
      case .keyDown: "keyDown"
      case .keyUp: "keyUp"
      case .beginGesture: "beginGesture"
      case .endGesture: "endGesture"
      case .magnify: "magnify"
      case .smartMagnify: "smartMagnify"
      case .swipe: "swipe"
      case .rotate: "rotate"
      case .gesture: "gesture"
      case .directTouch: "directTouch"
      case .tabletPoint: "tabletPoint"
      case .tabletProximity: "tabletProximity"
      case .pressure: "pressure"
      case .scrollWheel: "scrollWheel"
      case .changeMode: "changeMode"
      case .appKitDefined: "appKitDefined"
      case .applicationDefined: "applicationDefined"
      case .cursorUpdate: "cursorUpdate"
      case .flagsChanged: "flagsChanged"
      case .periodic: "periodic"
      case .quickLook: "quickLook"
      case .systemDefined: "systemDefined"
      default: "Unknown"
    }
  }
}

extension NSEvent.Phase: @retroactive CustomStringConvertible {
  public var description: String {
    switch self {
      case .began: "Began"
      case .changed: "Changed"
      case .stationary: "Stationary"
      case .ended: "Ended"
      case .cancelled: "Cancelled"
      case .mayBegin: "May Begin"
      default: "Unknown"
    }
  }
}

extension NSEvent.EventTypeMask: @retroactive CustomStringConvertible {
  public var description: String {
    switch self {
      case .any: "any"
      case .appKitDefined: "appKitDefined"
      case .applicationDefined: "applicationDefined"
      case .beginGesture: "beginGesture"
      case .changeMode: "changeMode"
      case .cursorUpdate: "cursorUpdate"
      case .directTouch: "directTouch"
      case .endGesture: "endGesture"
      case .flagsChanged: "flagsChanged"
      case .gesture: "gesture"
      case .keyDown: "keyDown"
      case .keyUp: "keyUp"
      case .leftMouseDown: "leftMouseDown"
      case .leftMouseDragged: "leftMouseDragged"
      case .leftMouseUp: "leftMouseUp"
      case .magnify: "magnify"
      case .mouseEntered: "mouseEntered"
      case .mouseExited: "mouseExited"
      case .mouseMoved: "mouseMoved"
      case .otherMouseDown: "otherMouseDown"
      case .otherMouseDragged: "otherMouseDragged"
      case .otherMouseUp: "otherMouseUp"
      case .periodic: "periodic"
      case .pressure: "pressure"
      case .rightMouseDown: "rightMouseDown"
      case .rightMouseDragged: "rightMouseDragged"
      case .rightMouseUp: "rightMouseUp"
      case .rotate: "rotate"
      case .scrollWheel: "scrollWheel"
      case .smartMagnify: "smartMagnify"
      case .swipe: "swipe"
      case .systemDefined: "systemDefined"
      case .tabletPoint: "tabletPoint"
      case .tabletProximity: "tabletProximity"
      default: "Unknown"
    }
  }
}

extension NSEvent.EventSubtype: @retroactive CustomStringConvertible {
  public var description: String {
    switch self {

      case .applicationActivated: "applicationActivated"
      case .applicationDeactivated: "applicationDeactivated"
      case .screenChanged: "screenChanged"
      case .windowExposed: "windowExposed"
      case .windowMoved: "windowMoved"
      case .touch: "touch"
      case .powerOff: "powerOff"
      case .mouseEvent: "mouseEvent"
      case .tabletPoint: "tabletPoint"
      case .tabletProximity: "tabletProximity"
      @unknown default: "Unknown"
    }
  }
}
