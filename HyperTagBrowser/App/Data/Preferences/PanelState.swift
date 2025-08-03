// created on 2/18/25 by robinsr

import Defaults


enum InspectorPanelState: String, Hashable, Defaults.Serializable {
  
  // Persists state of the inspector panel
  case container
  
  // Persists the state of the inspector panel's various sections
  case contentAttributes
  case currentTags
  case searchTags
  case replaceContent
  case contentThumbnail
  
  static let defaults: Set<Self> = [.contentAttributes, .currentTags, .searchTags]
}
