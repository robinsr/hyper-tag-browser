// created on 2/2/25 by robinsr


/**
 Defines the different contextual states in which a `FilteringTag` could find itself. This context
 determines which `ContextMenu` actions are available or irrelevant.
 
  - Filtering: Using a `FilteringTag` for refining search/browse/listing results. Values are:
    - `whenAppliedAsQueryFilter`: The tag is currently applied as a filter.
    - `whenSuggestedAsQueryFilter`: The tag is suggested as a filter but not currently applied.
  - Association: Attaching a `FilteringTag` to a specific content item (via `TagRecordIndex`). Values are:
    - `whenAppliedAsContentTag`: The tag is currently associated with a content item.
    - `whenSuggestedAsContentTag`: The tag is suggested for association but not currently applied.
 */
enum TagMenuContext: String {
  case whenAppliedAsQueryFilter
  case whenAppliedAsContentTag
  case whenSuggestedAsQueryFilter
  case whenSuggestedAsContentTag
}
