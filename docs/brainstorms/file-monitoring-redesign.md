# File Monitoring Redesign

**Status:** In-progress brainstorm — open questions remain (see bottom)  
**Date:** 2026-08-25

---

## Current Implementation (Audit)

### What exists

The current system uses the [`FileMonitor`](https://github.com/aus-der-Technik/FileMonitor) SPM
package (an FSEvents wrapper) inside a `FolderObserver` actor. It lives entirely inside the app
process and is fragile.

**Key files:**
- `App/Data/Runtime/FolderObserver.swift` — wraps FileMonitor, emits `FolderObserverEvent` stream
- `App/Data/ViewModels/App/AppViewModel+Files.swift` — consumes events, routes to new/moved handlers
- `App/Data/ViewModels/App/AppViewModel+Indexes.swift` — `doIndexDirectory()` manages observer lifecycle
- `App/Services/Indexer/Records/Content/IndexHistory.swift` — audit table + SQLite triggers
- `App/Services/Indexer/Records/Content/IndexRecord+Update.swift` — update operations that fire triggers
- `App/Services/Indexer/Migrations/DBMigration.swift` — IndexHistory table + trigger migrations

### Data flow

```
File system change
  → FileMonitor (FSEvents)
  → FolderObserver.stream
  → AppViewModel._handleFolderEvent()
      ├─ .unknown → _handleNewFile() → creates IndexRecord
      └─ .known   → _handleMovedIndex() → updates IndexRecord location
  → SQLite AFTER UPDATE trigger fires
  → app_content_indices_history row inserted (fsStatus = 'pending')
  → fsStatus updated to 'synced' or 'failed'
```

### Why it's broken

- `.changed` and `.deleted` events are **completely ignored** — updating a DB record triggers the
  SQLite triggers, which would re-fire the observer, causing an infinite loop
- `doIndexDirectory()` must **stop the observer, bulk index, then restart it** to avoid cascades
- File monitoring only works while the app is running — relocations that happen while the app is
  closed are lost
- `reloadDebouncer` and `IndexingQueue` actor add more complexity to manage the in-process races

---

## Redesign: SMAppService LaunchAgent + XPC

### Chosen approach

Replace the in-process FileMonitor with a **user-session LaunchAgent** registered via
`SMAppService.agent(plistName:)`. The daemon:

- Starts at user login, runs independently of the app
- Owns the FSEvents stream for all watched directories
- Writes directly to the SQLite DB (using WAL mode for concurrent access)
- Receives path management commands from the app via XPC

### Why this approach

| Requirement | In-process FileMonitor | LaunchAgent daemon |
|-------------|----------------------|-------------------|
| Records changes while app is closed | No | **Yes** |
| No infinite-loop workarounds | No | **Yes** (separate process, separate DB connection) |
| Survives app crash/quit | No | **Yes** |
| Ships with app (no separate installer) | Yes | **Yes** (embedded in app bundle) |

**Ruled out:**
- *XPC Service Extension* — macOS may suspend it when app is not running; doesn't satisfy offline recording
- *App-spawned background process* — exits when app quits; same limitation

### Architecture

```
┌─────────────────────────────────┐     ┌─────────────────────────────────────┐
│  HyperTagBrowser.app            │     │  com.robinsr.taggedfilebrowser.      │
│                                 │     │  monitor  (LaunchAgent)              │
│  AppViewModel                   │     │                                      │
│    ├─ GRDB ValueObservation ────┼─────┼── SQLite DB (WAL mode) ◄────────────┤
│    │   (auto-refresh on write)  │     │    app_content_indices               │
│    │                            │     │    app_content_indices_history       │
│    └─ XPC client ──────────────►│─XPC─►  XPC service                        │
│         addWatchedPath(url)     │     │    ├─ FSEvents stream                │
│         removeWatchedPath(url)  │     │    ├─ Watched path registry          │
│                                 │     │    └─ DB write operations            │
└─────────────────────────────────┘     └─────────────────────────────────────┘
```

### Responsibilities

**App (HyperTagBrowser.app):**
- Registers/unregisters the LaunchAgent via `SMAppService` on first launch
- Sends XPC messages to add/remove watched paths when user changes folder selection
- Reads DB via GRDB (read-only perspective; all writes come from daemon)
- GRDB `ValueObservation` on relevant tables triggers UI refresh automatically — no daemon → app
  notification channel needed

**Daemon (monitor LaunchAgent):**
- Receives watched path list via XPC; persists it (plist or DB table) for reboot recovery
- Opens FSEvents stream for each watched path
- On file system events: writes to `app_content_indices` and `app_content_indices_history`
- Manages SQLite connection with WAL mode enabled

### What goes away

- `FileMonitor` SPM dependency — removed entirely
- `FolderObserver` actor — removed
- The observer start/stop dance in `doIndexDirectory()` — no longer needed
- The infinite-loop workaround (ignoring `.changed`/`.deleted`) — no longer needed
- `reloadDebouncer` — may be replaceable with GRDB observation debounce or removed

### What stays

- `app_content_indices_history` table and its `fsStatus` workflow (pending → synced/failed)
- SQLite triggers on `location` and `name` columns (still useful as an audit trail; daemon may
  write directly rather than relying on them — TBD)
- `IndexRecord+Update.swift` update operations (daemon will call equivalent logic)
- `GRDB` as the DB layer (daemon uses GRDB too, or raw SQLite — TBD)

---

## Open Questions

### 1. File identity across relocations (not yet decided)

When a file moves from `/path/A/foo.mp4` to `/path/B/foo.mp4`, the daemon needs to determine
whether it's the same `IndexRecord`. Three candidates:

| Approach | Reliability | DB impact | Notes |
|----------|-------------|-----------|-------|
| **inode** | Good for local moves; breaks across volumes | None (already in DB?) | Inodes can be recycled |
| **NSURL bookmark data** | Best — survives renames, moves, some volume changes | Requires storing bookmark blob per record | Apple's designed solution |
| **FSEvents rename correlation** | Good — OS pairs "removed" + "appeared" in same batch | None | Requires `kFSEventStreamCreateFlagFileEvents`; event batch must be processed atomically |

### 2. Watched path persistence in daemon

How does the daemon remember which paths to watch after a reboot (before the app sends XPC
messages)? Options: a dedicated plist in `~/Library/Application Support/`, or a
`watched_folders` table in the shared SQLite DB.

### 3. Daemon's DB access layer

Should the daemon use GRDB (shared Swift package) or raw SQLite C API? GRDB is cleaner but
means the daemon target also depends on it. Raw SQLite avoids the dependency but duplicates
schema knowledge.

### 4. IndexHistory triggers — keep or replace?

The current SQLite triggers auto-populate `IndexHistory` on UPDATE. With the daemon owning
writes, it could write `IndexHistory` rows directly (more explicit, easier to reason about)
instead of relying on triggers. Or keep the triggers as a safety net.
