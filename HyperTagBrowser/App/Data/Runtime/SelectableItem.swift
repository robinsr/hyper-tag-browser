// created on 5/31/25 by robinsr

import SwiftUI


/**
 * Conforming to `SelectableOptions` allows a type to provide a list of `SelectOption` items
 * that can be used in a selection context, such as a menu or a list of options.
 */
protocol SelectableOptions<Value> {
  associatedtype Value: Hashable
  
  static var asSelectables: [SelectOption<Value>] { get }
}


/**
 * A structure representing an option that can be selected in a menu or list.
 */
struct SelectOption<Value>: Identifiable, MenuActionable where Value: Hashable {
  let id = UUID()
  let value: Value
  let label: String
  var icon: String?
  var disabled: Bool = false
}



/**
 * A container for a generic item that can be selected or deselected.
 */
struct SelectableItem<T: Hashable> : Identifiable, Equatable {
  var id: String = .randomIdentifier(10)
  var selected: Bool = true
  var item: T
}



/**
 * Defines various states and interactions for selectable items.
 */
struct SelectionItem {
  
  /**
   * A function type that defines the callback for when an item is tapped.
   */
  typealias ItemTappedFn = (SelectionItem.Interaction, EventModifiers) -> Void
  
  /**
   * Defines the various states applicable to a selectable item. `State` is not mutually exclusive; an item can
   * be in multiple states at once, such as being both `active` and `hover`. Use of a `State` value implies that
   * the item has at least this state, and this state is the most pertinent to the current context.
   *
   * The exception is the `none` state, which indicates that the item is not currently selected or hovered over.
   */
  enum State: String, CaseIterable {
      /// Item is currently selected and focused
    case active
      
      /// Item is currently selected, but not fcoused
    case dimmed
    
      /// Item may be selected, but is currently hovered over
    case hover
    
      /// Item is not currently selected or hovered over
    case none
    
    /**
     * Returns a Configuration containing color values to apply to the item based on its state.
     */
    var colors: ColorConfig {
      switch self {
      case .active: ColorConfig.from(.blue, dimmingBy: 0.5)
      case .dimmed: ColorConfig.from(.blue.lighten(by: 0.25), dimmingBy: 0.4)
      case .hover: ColorConfig.from(.green, dimmingBy: 0.5)
      case .none: ColorConfig.useSame(.clear)
      }
    }
    
    var suggestedFillColor: Color { self.colors.fill }
    var suggestedStrokeColor: Color { self.colors.stroke }
  }

  
  /**
   * Defines a set of interactions performed on a selectable item.
   */
  enum Interaction: String, CaseIterable {
      /// Indicates the itention to select an item.
    case select
      /// Indicates the intention to deselect an item.
    case isSelected
      /// Indicates the intention to toggle the selection state of an item.
    case secondary
  }
  
  struct ActiveState: OptionSet {
    let rawValue: Int
    
    static let active = ActiveState(rawValue: 1 << 0) // Effect when item is not selected
    static let inactive = ActiveState(rawValue: 1 << 1) // Effect when item is selected
    
    static let all: ActiveState = [.active, .inactive] // All effects combined
    static let none: ActiveState = [] // No effects
    
    var isEmpty: Bool { self.rawValue == 0 }
  }
  
  
  /**
   * Actually kinda useless
   */
  struct ColorConfig {
    let stroke: Color
    let fill: Color
    
    static func useSame(_ color: Color) -> ColorConfig {
      ColorConfig(stroke: color, fill: color)
    }
    
    static func from(_ color: Color, dimmingBy opacity: Double) -> ColorConfig {
      ColorConfig(stroke: color, fill: color.opacity(opacity))
    }
  }
}


/*
 /**
  * A builder for constructing a `State` based on various conditions.
  */
 class Builder {
   private var isActive: Bool = false
   private var isDimmed: Bool = false
   private var isHovered: Bool = false
   private var orderOfPriority: [State] = []
   
   init() {}
   
   func setActive(_ active: Bool) -> Builder {
     self.isActive = active
     return self
   }
   
   func setDimmed(_ dimmed: Bool) -> Builder {
     self.isDimmed = dimmed
     return self
   }
   
   func setHovered(_ hovered: Bool) -> Builder {
     self.isHovered = hovered
     return self
   }
   
   func withPriorityOrdering(_ states: [State]) -> Builder {
     self.orderOfPriority = states
     return self
   }
   
   func get() -> State {
     let activeStates: [State] = [
       isActive ? .active : nil,
       isDimmed ? .dimmed : nil,
       isHovered ? .hover : nil
     ].compactMap { $0 }
     
     for state in orderOfPriority {
       if activeStates.contains(state) {
         return state
       }
     }
     
     return .none
   }
 }
 
 static func builder() -> Builder {
   Builder()
 }
 */
