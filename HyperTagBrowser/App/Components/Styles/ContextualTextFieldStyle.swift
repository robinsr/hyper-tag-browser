// created on 4/30/25 by robinsr

import SwiftUI


struct ContextualTextFieldStyle: TextFieldStyle {
  
  /**
   * Specifies the context in which the TextField to be styled is being used
   *
   * - `primaryField`: Is either the *only field* in a particular UX, or is visually distinct from other fields
   * - `inlineField`: Is used inline with other fields
   * - `panelField`: Is used in a panel, such as a sidebar or inspector
   * - `prominent`: Is used in a prominent position, such as a searchbar; distinct from `primaryField` in that...
   * - `sidebar`: Is used in a sidebar
   * - `form`: Is used in a form
   */
  enum ViewContext {
    case primaryField
    case inlineField
    case panelField
    case prominent
    case sidebar
    case form
    
    var style: StyleClass {
      switch self {
      case .primaryField:
        StyleClass.listItem
      case .prominent:
        StyleClass.listEditorInput
      default:
        StyleClass.controlLabel
      }
    }
  }
  
  enum MessagePlacement {
    case inline
    case below
    
    var alignment: Alignment {
      switch self {
      case .inline: .centerLastTextBaseline
      case .below: .leading
      }
    }
    
    var axis: Axis {
      switch self {
      case .inline: .horizontal
      case .below: .vertical
      }
    }
  }
  
  enum IconPlacement {
    case leading
    case trailing
    
    var alignment: HorizontalAlignment {
      switch self {
      case .leading: .leading
      case .trailing: .trailing
      }
    }
  }
  
  var context: ViewContext = .form
  var message: Binding<String?> = .constant(nil)
  var messagePlacement: MessagePlacement = .below
  var icon: SymbolIcon = .noIcon
  var iconPlacement: IconPlacement = .leading
  
  var hzDirection: SubviewOrdering {
    switch iconPlacement {
    case .leading: SubviewOrdering.normal
    case .trailing: SubviewOrdering.reversed
    }
  }
  
  func _body(configuration: TextField<Self._Label>) -> some View {
    StackView(axis: .horizontal, direction: hzDirection, align: .center, spacing: 4) {

      Image(icon)
        .font(context.style.font)
        .foregroundColor(.primary.opacity(0.7))
        //.foregroundStyle(context.style.config.color)
        .hidden(icon == .noIcon)
      
      StackView(axis: messagePlacement.axis, align: messagePlacement.alignment, spacing: 2) {
        configuration
          .lineLimit(1)
          .font(context.style.font)
          //.foregroundStyle(context.style.config.color)
        
        Text(message.wrappedValue ?? "")
          .font(.caption)
          .foregroundStyle(.red)
          .visible(message.wrappedValue != nil)
      }
    }
    .modify(when: context == .form) { view in
      view
        .textFieldStyle(.roundedBorder)
        .controlSize(.extraLarge)
    }
    .modify(when: context == .panelField) { view in
      view
        .textFieldStyle(.plain)
        .controlSize(.extraLarge)
        .frame(idealWidth: 250)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 4).fill(.black.opacity(0.6)))
    }
    .modify(when: context == .prominent) { view in
      view
        .textFieldStyle(.plain)
    }
    .modify(when: context == .sidebar) { view in
      view
        .textFieldStyle(.roundedBorder)
    }
  }
}


extension TextFieldStyle where Self == ContextualTextFieldStyle {
  /**
   Applies `.panelField` style to a `TextField`.
   
    ```swift
    TextField("Enter your name", text: $name)
      .textFieldStyle(.panelField)
    ```
   */
  static var panelField: ContextualTextFieldStyle {
    .init(context: .panelField)
  }
  
  /**
   Applies `.panelField` style to a `TextField` and binds a error message to the field.
   
    ```swift
    TextField("Enter your name", text: $name)
      .textFieldStyle(.panelField(err: $nameError))
    ```
   */
  static func panelField(err: Binding<String?>) -> ContextualTextFieldStyle {
    .init(context: .panelField, message: err)
  }
  
  
  /**
    Applies `.form` style to a `TextField` and binds a error message to the field.
    
    ```swift
    TextField("Enter your name", text: $name)
      .textFieldStyle(.form(err: $nameError))
    ```
   */
  static func form(err: Binding<String?> = .constant(nil)) -> ContextualTextFieldStyle {
    .init(context: .form, message: err)
  }
  
  /**
    Applies `.inlineField` style to a `TextField` and binds a error message to the field.
    
    ```swift
    TextField("Enter your name", text: $name)
      .textFieldStyle(.form(err: $nameError))
    ```
   */
  static func inlineField(err: Binding<String?> = .constant(nil)) -> ContextualTextFieldStyle {
    .init(context: .inlineField, message: err)
  }
  
  /**
    Applies `.primaryField` style to a `TextField`.
    
    ```swift
    TextField("Enter your name", text: $name)
      .textFieldStyle(.primaryField)
    ```
   */
  static func primaryField(err: Binding<String?> = .constant(nil)) -> ContextualTextFieldStyle {
    .init(context: .primaryField, message: err)
  }
  
  /**
    Applies `.sidebar` style to a `TextField`.
    
    ```swift
    TextField("Enter your name", text: $name)
      .textFieldStyle(.sidebar)
    ```
   */
  static var prominent: ContextualTextFieldStyle {
    .init(context: .prominent)
  }
  
  /**
    Applies `.prominent` style to a `TextField` and binds a error message to the field.
    
    ```swift
    TextField("Enter your name", text: $name)
      .textFieldStyle(.prominent(err: $nameError))
    ```
   */
  static func prominent(err: Binding<String?> = .constant(nil)) -> ContextualTextFieldStyle {
    .init(context: .prominent, message: err)
  }
  
  /**
    Applies `.prominent` style to a `TextField` and binds a error message to the field.
    
    ```swift
    TextField("Enter your name", text: $name)
      .textFieldStyle(.prominent(icon: .person, err: $nameError))
    ```
   */
  static func prominent(icon: SymbolIcon, err: Binding<String?> = .constant(nil)) -> ContextualTextFieldStyle {
    .init(context: .prominent, message: err, icon: icon, iconPlacement: .leading)
  }
  
  /**
    Applies `.sidebar` style to a `TextField`.
    
    ```swift
    TextField("Enter your name", text: $name)
      .textFieldStyle(.sidebar)
    ```
   */
  static func sidebar(err: Binding<String?> = .constant(nil)) -> ContextualTextFieldStyle {
    .init(context: .sidebar, message: err)
  }
}


