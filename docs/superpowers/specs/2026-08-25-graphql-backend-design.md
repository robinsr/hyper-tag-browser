# GraphQL Backend — Design Spec

**Date:** 2026-08-25  
**Status:** Draft — pending user review  
**Scope:** Read-only GraphQL server (Phase 1); full CRUD deferred to Phase 2

---

## Overview

A Go-based GraphQL server that exposes HyperTagBrowser's SQLite metadata store over HTTP. The server ships as a compiled binary inside the macOS `.app` bundle, managed by launchd as a Login Item agent. A React web UI (future work) connects to it on localhost. This is Phase 1: read-only queries only.

---

## Goals

- Expose all core domain entities (files, tags, queues, bookmarks, saved queries, history) as a queryable GraphQL API
- Ship as a native binary with the macOS app — no external runtime dependencies
- Support the app being closed while the server continues serving read queries
- Lay a schema foundation that Phase 2 mutations can extend without breaking changes

---

## Architecture

### Process model

```
macOS App (Swift/SwiftUI)
  └─ SMAppService.register() ──► launchd
                                    └─ HyperTagBrowserServer (Go binary)
                                          ├─ reads server-config.json
                                          ├─ opens SQLite (read-only in Phase 1)
                                          └─ serves GraphQL HTTP on localhost:PORT

React Web UI (browser) ──────────────────────────► localhost:PORT/graphql
```

- The Go binary is a Login Item agent registered via `SMAppService` (macOS 13+)
- launchd owns the process lifecycle: starts it, restarts on crash, keeps it alive after the app quits
- The Swift app enables/disables the server from a settings panel via `SMAppService.mainApp.register()` / `unregister()`
- Communication between the Swift app and Go server is plain HTTP — no XPC messaging

### Repo layout

```
HyperTagBrowser/           # existing Xcode project
server/                    # new Go module
  go.mod
  go.sum
  main.go
  graph/
    schema.graphqls        # GraphQL schema (gqlgen source of truth)
    resolver.go            # gqlgen-generated resolver interface
    resolvers/             # resolver implementations (one file per domain)
      files.go
      tags.go
      queues.go
      bookmarks.go
      saved_queries.go
  db/
    db.go                  # SQLite connection setup
    queries/               # raw SQL query functions
  config/
    config.go              # reads and watches server-config.json
```

An Xcode build phase compiles the Go binary (`go build ./server`) and copies it into `Contents/MacOS/` inside the `.app` bundle alongside the main executable.

### Server configuration

The Swift app writes `~/Library/Application Support/com.robinsr.taggedfilebrowser/server-config.json` on launch and whenever relevant settings change. The Go server reads it on startup and watches it for live changes via `fsnotify`.

```json
{
  "port": 8765,
  "db_path": "/Users/ryan/Library/Application Support/com.robinsr.taggedfilebrowser/db.sqlite",
  "log_level": "info",
  "app_running": true
}
```

| Field | Purpose |
|---|---|
| `port` | HTTP port for the GraphQL endpoint |
| `db_path` | Absolute path to the SQLite database file |
| `log_level` | `debug` / `info` / `warn` |
| `app_running` | Set `true` on app launch, `false` on quit; server uses this to signal limited-mode |

---

## GraphQL Schema

### Scalars and enums

```graphql
scalar DateTime   # ISO8601 string

enum TagType {
  TAG  ARTIST  CREATOR  CONTRIBUTOR  OWNER  QUEUE  RELATED
  CREATED_BEFORE  CREATED_ON_OR_BEFORE  CREATED_ON  CREATED_ON_OR_AFTER  CREATED_AFTER
}

enum TagDomain { DESCRIPTIVE  ATTRIBUTION  QUEUE  UNLABELED  CREATION }

enum TagEntryType { NORMAL  ALIAS }

enum TagFilterEffect { INCLUSIVE  EXCLUSIVE }

enum FilterOperator { ALL  ANY }

enum ContentTypeGroup {
  FOLDERS  IMAGES  VIDEO  DATABASE  USER  NON_USER  CONTENT  ALL  EMPTY
}

enum FileVisibility  { NORMAL  HIDDEN  LOST }      # stored values
enum VisibilityFilter { NORMAL  HIDDEN  LOST  ANY } # filter input only

enum TraversalMode { RECURSIVE  FLAT }

enum SortOrder {
  NAME_ASC  NAME_DESC
  CREATED_ASC  CREATED_DESC
  MODIFIED_ASC  MODIFIED_DESC
  SIZE_ASC  SIZE_DESC
}

enum HistoryColumn { NAME  LOCATION }

enum FsStatus { PENDING  SYNCED  FAILED }
```

### Core types

```graphql
type File {
  id: ID!
  name: String!
  location: String!
  type: String!           # UTType identifier string
  size: Int!
  created: DateTime!
  modified: DateTime!
  comment: String!
  volume: String!
  visibility: FileVisibility!

  tags: [Tag!]!
  tagCount: Int!
  bookmarked: Boolean!
  queues: [Queue!]!
  history: [FileHistoryEntry!]!
}

type Tag {
  id: ID!
  tagValue: String!
  tagType: TagType!
  domain: TagDomain!      # computed from tagType, not stored
  entryType: TagEntryType!
  aliases: [Tag!]!        # tags whose relatedId points to this tag
  parent: Tag             # populated if this tag is an alias
  fileCount: Int!         # usage count across all indexed files
  files(first: Int, after: String): FileConnection!
}

type Queue {
  id: ID!
  name: String!
  created: DateTime!
  itemCount: Int!
  items: [QueueItem!]!
}

type QueueItem {
  id: ID!
  file: File!
  addedAt: DateTime!
  completed: Boolean!
}

type Bookmark {
  id: ID!
  file: File!
  createdAt: DateTime!
}

type FileHistoryEntry {
  id: ID!
  timestamp: DateTime!
  column: HistoryColumn!
  oldValue: String!
  newValue: String!
  fsStatus: FsStatus!
  indexType: String       # UTType at time of change; nullable
}

type SavedQuery {
  id: ID!
  name: String!
  filter: FileFilter!
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

### Filter output types (for SavedQuery)

```graphql
type TagCriterion {
  effect: TagFilterEffect!
  tagType: TagType!
  tagValue: String!
}

type TagsFilter {
  enabled: Boolean!
  operator: FilterOperator!
  criteria: [TagCriterion!]!
}

type NameFilter {
  operator: FilterOperator!
  values: [String!]!
}

type FileFilter {
  root: String
  traversal: TraversalMode
  sortBy: SortOrder
  visibility: VisibilityFilter
  types: [ContentTypeGroup!]
  nameMatching: NameFilter
  excludeContent: NameFilter
  tagsMatching: TagsFilter
}
```

### Filter input types (for queries — mirrors FileFilter)

```graphql
input TagCriterionInput {
  effect: TagFilterEffect!
  tagType: TagType!
  tagValue: String!
}

input TagsMatchingInput {
  enabled: Boolean!
  operator: FilterOperator!
  criteria: [TagCriterionInput!]!
}

input NameMatchingInput {
  operator: FilterOperator!
  values: [String!]!
}

input FileFilterInput {
  root: String
  traversal: TraversalMode
  sortBy: SortOrder
  visibility: VisibilityFilter
  types: [ContentTypeGroup!]
  nameMatching: NameMatchingInput
  excludeContent: NameMatchingInput
  tagsMatching: TagsMatchingInput
}
```

### Relay connection types

Used for `files` and `Tag.files` only. All other collections use plain arrays.

```graphql
type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

type FileEdge {
  cursor: String!
  node: File!
}

type FileConnection {
  edges: [FileEdge!]!
  nodes: [File!]!
  pageInfo: PageInfo!
  totalCount: Int!
}
```

### Root Query type

```graphql
type Query {
  # Files
  file(id: ID!): File
  files(filter: FileFilterInput, first: Int, after: String): FileConnection!

  # Tags
  tag(id: ID!): Tag
  tags(domain: TagDomain, type: TagType): [Tag!]!

  # Saved queries
  savedQuery(id: ID!): SavedQuery
  savedQueries: [SavedQuery!]!
  savedQueryResults(id: ID!, first: Int, after: String): FileConnection!

  # Bookmarks
  bookmarks: [Bookmark!]!

  # Queues
  queue(id: ID!): Queue
  queues: [Queue!]!
}
```

---

## Database access

- Phase 1 opens SQLite in **read-only mode** (`?mode=ro` on the connection string)
- The Go server uses `modernc.org/sqlite` (pure Go, no cgo) — avoids CGo toolchain complexity and simplifies universal binary builds targeting both arm64 and x86_64
- No ORM — raw SQL queries in `server/db/queries/`, one file per domain, returning typed Go structs that gqlgen resolvers map to GraphQL types
- The existing SQLite views (`app_content_tag_item_values`, `app_content_tag_items_joined`) are used directly where they simplify resolver queries

---

## Implementation approach (gqlgen)

gqlgen is schema-first: you write `schema.graphqls`, run `go generate`, and it produces typed Go interfaces. You fill in the resolver bodies.

**Sequence per schema change:**
1. Edit `graph/schema.graphqls`
2. Run `go generate ./...` to regenerate resolver interfaces
3. Implement resolver bodies in `graph/resolvers/`
4. Update SQL in `db/queries/` if needed

The `TagDomain` field on `Tag` is computed in the resolver (a switch on `tagType`) — it does not require a database query.

---

## Deferred (Phase 2)

- Mutations: tag assignment, saved query CRUD, queue management, visibility updates
- Authentication / access token for the local endpoint
- Web UI tech choice and integration (browser vs `WKWebView`)
- Full-text or Spotlight-backed search query

---

## Open questions (carry forward)

- Exact port number for `server-config.json` default (needs to avoid common conflicts)
- Whether `File.history` should be paginated (could be long for frequently-renamed files)
- Whether `SavedQuery.filter` deserializing the JSON blob should be strict (fail on unknown fields) or lenient (ignore unknown fields) to handle schema evolution gracefully
