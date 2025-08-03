// created on 3/31/25 by robinsr


/**
 * Represents the core type of a content item in the app.
 */
typealias ContentItem = IndexInfoRecord


extension ContentItem {

    /// The title of the content item.
    var title: String {
        return self.name
    }
}
