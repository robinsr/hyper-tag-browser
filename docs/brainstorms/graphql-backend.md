# GraphQL Backend — Brainstorm Checkpoint

**Date:** 2026-08-24  
**Status:** In progress — paused mid-brainstorm

---

## Goal

Build a GraphQL backend on top of the existing SQLite metadata store to enable:
1. A React web UI as an alternative frontend (primary portfolio motivation)
2. Full CRUD operations over files, tags, saved queries, queues, bookmarks

The backend **ships with the macOS app** — it's not a separate service.

---

## Decisions Made

### Language: Go (gqlgen)
- Go compiles to a static binary — no runtime to bundle
- Binary drops into `.app` bundle (`Contents/MacOS/` or `Contents/Resources/`)
- Swift app launches it as a subprocess on startup, manages its lifecycle
- GraphQL server listens on `localhost:PORT`; React UI connects to it
- This is the same helper-process pattern used by apps like Tailscale

Alternatives considered and ruled out:
- **TypeScript/Node.js** — requires bundling Node runtime (~50–100MB) or using Bun compile-to-binary (less mature); not clean for macOS app distribution
- **Python** — same bundling problem; no system Python on modern macOS
- **Swift/Vapor** — no bundling issue, but thin ecosystem, not portfolio-valuable

### Scope: Read-only first, full CRUD target
- **Intermediate deliverable:** read-only queries (browsing files, tags, saved queries, bookmarks)
- **Full target:** mutations for tagging, managing saved queries, queues, etc.

---

## Open Questions (to resume here)

- [ ] Repo structure: same repo (`server/` subdir) or separate repo?
- [ ] How does Swift launch/manage the Go subprocess? (XPC vs plain subprocess, port negotiation)
- [ ] Authentication/security for the local GraphQL endpoint (localhost only? token?)
- [ ] GraphQL schema design — what are the root query types, connections, nested resolvers?
- [ ] Web UI tech: browser-based or embedded `WKWebView` in the app?
- [ ] Code generation strategy: gqlgen schema-first vs resolvers approach

---

## Existing Database Schema (summary)

8 tables + 3 views, well-structured with full referential integrity and cascade deletes.

### Tables
| Table | Record Type | Purpose |
|---|---|---|
| `app_content_indices` | `IndexRecord` | Core file/folder index (name, location, type, size, dates) |
| `app_content_tags` | `TagRecord` | Tag definitions (value, type, alias support via self-FK) |
| `app_content_tag_items` | `IndexTagRecord` | Many-to-many join: files ↔ tags |
| `app_bookmarks` | `BookmarkRecord` | Bookmarked files |
| `app_workqueues` | `QueueRecord` | Named batch-processing queues |
| `app_workqueue_items` | `QueueItemRecord` | Files in queues with completion status |
| `app_saved_content_queries` | `SavedQueryRecord` | Persisted search filters (JSON blob) |
| `app_content_indices_history` | `IndexHistory` | Audit trail for name/location changes |

### Views
| View | Purpose |
|---|---|
| `app_content_tag_item_values` | Tags with filter values per content item |
| `app_content_tag_items_joined` | Aggregated tag string + count per file |
| IndexTagCountRecord | Tag count per file |

### Key joined/composite types (not tables)
- `IndexInfoRecord` — IndexRecord + tags + queues + tag count (main list view model)
- `BookmarkInfoRecord` — BookmarkRecord + IndexRecord
- `CountedTagRecord` — TagRecord + usage count

### Notable schema details
- Tag aliases: tags can point to a parent tag via `relatedId` (self-referential FK)
- Generated columns: `filterValue` on tags, `tagName` on queues (pipe-separated for SQL filtering)
- Audit trail: `IndexHistory` tracks name/location changes with `fsStatus` (pending/synced/failed)
- SavedQuery stores filters as a JSON blob — will need careful GraphQL representation
- Indexes added Aug 2025 on all common filter columns

---

## Next Steps (when resuming)

1. Decide repo structure
2. Sketch GraphQL schema (root types, queries, connections)
3. Discuss Swift ↔ Go subprocess lifecycle management
4. Proceed to full architectural design → spec → implementation plan
