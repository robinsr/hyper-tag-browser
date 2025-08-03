// created on 3/6/25 by robinsr


import AppKit


extension NSWindow {
  private enum AssociatedKeys {
    static let cancellable = ObjectAssociation<AnyCancellable?>()
  }

  func makeVibrant() {
    // So there seems to be a visual effect view already created by NSWindow.
    // If we can attach ourselves to it and make it a vibrant one - awesome.
    // If not, let's just add our view as a first one so it is vibrant anyways.
    guard let visualEffectView = contentView?.superview?.subviews.lazy.compactMap({ $0 as? NSVisualEffectView }).first
    else {
      contentView?.superview?.insertVibrancyView(material: .underWindowBackground)
      return
    }

    visualEffectView.blendingMode = .behindWindow
    visualEffectView.material = .underWindowBackground

    AssociatedKeys.cancellable[self] = visualEffectView.publisher(for: \.effectiveAppearance)
      .sink { _ in
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.material = .underWindowBackground
      }
  }
}

final class ObjectAssociation<Value: Any> {
  private let defaultValue: Value
  private let policy: AssociationPolicy

  init(defaultValue: Value, policy: AssociationPolicy = .retainNonatomic) {
    self.defaultValue = defaultValue
    self.policy = policy
  }

  subscript(index: AnyObject) -> Value {
    get {
      objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as? Value ?? defaultValue
    }
    set {
      objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, policy.rawValue)
    }
  }
}

extension ObjectAssociation {
  convenience init<T>(policy: AssociationPolicy = .retainNonatomic) where Value == T? {
    self.init(defaultValue: nil, policy: policy)
  }
}

enum AssociationPolicy {
  case assign
  case retainNonatomic
  case copyNonatomic
  case retain
  case copy

  var rawValue: objc_AssociationPolicy {
    switch self {
    case .assign:
      .OBJC_ASSOCIATION_ASSIGN
    case .retainNonatomic:
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    case .copyNonatomic:
      .OBJC_ASSOCIATION_COPY_NONATOMIC
    case .retain:
      .OBJC_ASSOCIATION_RETAIN
    case .copy:
      .OBJC_ASSOCIATION_COPY
    }
  }
}
