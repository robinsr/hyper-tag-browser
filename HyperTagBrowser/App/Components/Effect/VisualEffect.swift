import SwiftUI


/// Bridge AppKit's NSVisualEffectView into SwiftUI
struct VisualEffectView: NSViewRepresentable {
  var material: NSVisualEffectView.Material = .headerView
  var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
  var state: NSVisualEffectView.State = .active
  var emphasized: Bool = true

  func makeNSView(context: Context) -> NSVisualEffectView {
    context.coordinator.visualEffectView
  }

  func updateNSView(_ view: NSVisualEffectView, context: Context) {

  }

  func makeCoordinator() -> Coordinator {
    Coordinator(
      material: material,
      blendingMode: blendingMode,
      state: state,
      emphasized: emphasized
    )
  }

  class Coordinator {
    let visualEffectView = NSVisualEffectView()

    init(
      material: NSVisualEffectView.Material,
      blendingMode: NSVisualEffectView.BlendingMode,
      state: NSVisualEffectView.State,
      emphasized: Bool
    ) {
      visualEffectView.material = material
      visualEffectView.blendingMode = blendingMode
      visualEffectView.state = state
      visualEffectView.isEmphasized = emphasized
    }
  }
}
