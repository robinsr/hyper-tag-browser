# HyperTagBrowser

A macOS file browser with tag-based organization and filtering. Built with SwiftUI for macOS 15+.


## Screenshots

### Browse

| Main                                                                                                                                          | Single selection                                                                                                                                       | Multi-selection                                                                                                                                           |
| --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ![Browse](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/010-hypertagbrowser-browse-main.png) | ![Single](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/011-hypertagbrowser-browse-cursor-single.png) | ![Multi](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/012-hypertagbrowser-browse-cursor-multi-item.png) |


### Filtering

| Refinements panel                                                                                                                                         | Filters applied                                                                                                                                               | Exclude mode                                                                                                                                                 |
| --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ![Refinements](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/013-hypertagbrowser-browse-refinements.png) | ![Applied](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/014-hypertagbrowser-browse-refinements-applied.png) | ![Exclude](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/015-hypertagbrowser-browser-refine-not-filter.png) |


### Search & Tagging

| Search sheet                                                                                                                                        | Tag sheet                                                                                                                                                   | Stashed tags                                                                                                                                    |
| --------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| ![Search](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/020-hypertagbrowser-search-sheet-main.png) | ![Tags](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/030-hypertagbrowser-browse-tag-sheet-multi-item.png) | ![Stashed](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/016-hypertagbrowser-stashed-tags.png) |


### Detail view

| Light                                                                                                                                              | Dark                                                                                                                                             |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| ![Light](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/040-hypertagbrowser-detail-main-light.png) | ![Dark](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/040-hypertagbrowser-detail-main-dark.png) |


### Settings

| General                                                                                                                                             | Appearance                                                                                                                                                |
| --------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ![General](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/080-hypertagbrowser-settings-general.png) | ![Appearance](https://raw.githubusercontent.com/robinsr/hyper-tag-browser/refs/heads/main/screenshots/thumbs/081-hypertagbrowser-settings-appearance.png) |


## Requirements

- macOS 15.0+
- Xcode 16+
- Apple Silicon or Intel

## Setup

```bash
git clone https://github.com/robinsr/HyperTagBrowser.git
cd HyperTagBrowser
open HyperTagBrowser.xcodeproj
```

Dependencies are managed via Swift Package Manager and will resolve on first build:

- [GRDB](https://github.com/groue/GRDB.swift) — SQLite database layer
- [GRDBQuery](https://github.com/groue/GRDBQuery) — reactive database queries
- [Factory](https://github.com/hmlongco/Factory) — dependency injection
- [Defaults](https://github.com/sindresorhus/Defaults) — user preferences
- [MacSettings](https://github.com/...) — settings UI

## Running Tests

```bash
  # All unit tests
  xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' -only-testing:HyperTagBrowserTests

  # Single test class
  xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' -only-testing:HyperTagBrowserTests/GRDBTagsTest

  # All UITests
  xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' -only-testing:HyperTagBrowserUITests
```

Test coverage includes unit tests for business logic and data models, UI interaction tests, and database/service integration tests.


## Architecture

MVVM with dependency injection via Factory. Database observations use GRDBQuery for reactive updates. UI is composed from modular SwiftUI views.

## Keyboard Shortcuts

| Action                | Shortcut    |
| --------------------- | ----------- |
| Quick Actions         | `⇧⌘P`       |
| Toggle Sidebar        | `⌃S`        |
| Filters               | `⌃F`        |
| Bookmarks             | `⌃B`        |
| Work Queues           | `⌃Q`        |
| Manage Tags           | `⌃T`        |
| Edit Tags             | `⌘E`        |
| Select All            | `⌘A`        |
| Navigate Back/Forward | `⌘[` / `⌘]` |


## Debug / Development

Development flags can be enabled in the settings panel:

- SQL query logging
- Performance metrics
- UI debugging tools

## License

MIT — see [LICENSE](LICENSE).