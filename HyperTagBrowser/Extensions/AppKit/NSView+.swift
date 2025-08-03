// created on 3/6/25 by robinsr

import AppKit


extension NSView {
  @discardableResult
  func insertVibrancyView(
    material: NSVisualEffectView.Material,
    blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
    appearanceName: NSAppearance.Name? = nil
  ) -> NSVisualEffectView {
    let view = NSVisualEffectView(frame: bounds)
    view.autoresizingMask = [.width, .height]
    view.material = material
    view.blendingMode = blendingMode

    if let appearanceName {
      view.appearance = NSAppearance(named: appearanceName)
    }

    addSubview(view, positioned: .below, relativeTo: nil)

    return view
  }
}
