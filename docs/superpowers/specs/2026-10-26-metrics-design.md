# Performance Metrics Redesign

**Date:** 2026-10-26
**Branch:** `2026-10-26-fix-metrics`
**Status:** Design approved, pending spec review

## Problem

The current metrics system (`App/Utilities/Metrics/`, `App/Utilities/Measure/`) is built on
OpenTelemetry but is only partially implemented: the default recorder is a no-op, the
Graphite recorder is fully commented out, histogram aggregation in `SelfTimer` is marked "not
working yet", and there is exactly one real call site (`AppDispatcher.dispatch(_:)`). Nothing
is persisted, so nothing can be analyzed after the fact.

Metrics exist solely to measure and improve app performance. The design is driven by two
questions:

1. **When indexing files, how long does each step in the indexing pipeline take?**
2. **As the SQLite database grows, which operations are most affected?**

Question 2 is longitudinal: it compares latency across weeks of use as the database grows. It
requires data that is persisted across sessions and correlated with database size.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Consumption model | Instruments signposts (live drill-down) **and** a local persistent metrics store (trends) | Signposts answer Q1 interactively; persistence is required for Q2 |
| Persistent store | Local SQLite file (`metrics.sqlite`), not StatsD/Graphite | No infrastructure; captures every session, including unplanned ones. StatsD can be added later as a second sink |
| When recording runs | Always on, all builds; `DevFlags.metrics_disable` kill switch | Day-to-day release usage against the real library is the data Q2 needs; often want metrics after the fact |
| Core implementation | Replace OpenTelemetry with a small in-house recorder | OTel's value is collector interoperability, which a local file doesn't need; the OTel metrics SDK is the part already causing friction; migration cost is one call site |

## Non-Goals

- Fixing performance problems the metrics reveal (e.g. xattr I/O inside the indexer write
  transaction). This work measures; fixes come after.
- A StatsD/Graphite/Prometheus exporter. The sink protocol must allow one, but it is not built.
- An in-app metrics viewer. Analysis is done with `sqlite3` and the canned queries file.
- Instrumenting thumbnails, Spotlight, or view rendering.

## Section 1: Components

All new code lives in `App/Utilities/Metrics/`. The OpenTelemetry-based files are deleted.

| Unit | Responsibility | Depends on |
|---|---|---|
| `MetricsRecorder` (protocol) | `span(_ name:, tags:) -> Span`, `timing(_ name:, ms:, tags:)`, `gauge(_ name:, value:, tags:)` | — |
| `Span` | Start/stop handle. Emits an `OSSignposter` interval; on stop, enqueues a raw span row. `child(_ name:, tags:)` creates a child span sharing the `traceId`. `stop(outcome:)` records `ok` / `error`. Tags may be added before stop (`span.tag("rows", 12)`) | `OSSignposter`, recorder's span buffer |
| `TimingAggregator` | Thread-safe (`Mutex`) map of `(name, tags) →` count, sum, min, max, and fixed log-scale bucket counts. `drain()` returns aggregates and resets | — |
| `MetricsSink` (protocol) | `write(session:)`, `write(spans:)`, `write(aggregates:snapshot:)` | — |
| `SQLiteMetricsSink` | Owns a GRDB `DatabaseQueue` at `~/Library/Application Support/<bundle id>/metrics.sqlite` with its own migrator and retention prune | GRDB |
| `MetricsFlusher` | Every 60s and at `applicationWillTerminate`: drains the aggregator and span buffer, takes a DB-size snapshot when due, writes to the sink | aggregator, sink, snapshot provider |
| `DefaultMetricsRecorder` | Composes the above | all of the above |
| `NoopMetricsRecorder` | Used when `DevFlags.metrics_disable` is set, when the sink cannot be opened, and as the test-target default | — |
| `SQLNormalizer` | Normalizes statement SQL and produces a stable 64-bit FNV-1a hash | — |
| `SQLStatementProfiler` | Installed via `db.trace(options: .profile)` in `GRDBIndexService.configure()`; normalizes and records `timing("sql", …)` | recorder, normalizer |

**Retained and adapted:** `SelfTimer` and `MetricSource` remain as thin conveniences on top of
`MetricsRecorder` (`timeExecution` records a `timing`; `MetricSource.name` becomes the timing
name).

**Removed:** `Telemetry.swift`, `NothingMetricsRecorder.swift`, `StdoutMetricsRecorder.swift`,
`GraphiteMetricsRecorder.swift`, `CodeMeasureKit.swift` (no callers) and `UnfairQueue.swift`
(used only by `CodeMeasureKit`), the `OpenTelemetryApi` import in
`Services/Indexer/Parameters/IndexParameters.swift`, and the `opentelemetry-swift` /
`opentelemetry-swift-core` package dependencies — all nine linked products: `OpenTelemetryApi`,
`OpenTelemetrySdk`, `OpenTelemetryConcurrency`, `OTelSwiftLog`, `PrometheusExporter`,
`ResourceExtension`, `SignPostIntegration`, `StdoutExporter`, `SwiftMetricsShim`. The project
file is the Xcode 27 JSON format (`HyperTagBrowser.xcodeproj/project.xcproj`); package removal
should be done through Xcode rather than hand-editing.

**Wiring:** a single Factory registration, `Container.metricsRecorder`, resolving to
`DefaultMetricsRecorder` unless `DevFlags.metrics_disable` is set. `--emit-metrics`
(`RunFlags.emitMetrics`) changes meaning to "also log each flush summary to the console".

## Section 2: Storage Schema

`metrics.sqlite` is independent of the main index database and has its own migrations.

```sql
CREATE TABLE sessions (
  id            TEXT PRIMARY KEY,      -- UUID
  started_at    DATETIME NOT NULL,
  ended_at      DATETIME,              -- set on clean termination
  app_version   TEXT NOT NULL,
  build_number  TEXT NOT NULL,
  os_version    TEXT NOT NULL,
  main_db_name  TEXT NOT NULL
);

CREATE TABLE spans (
  id            TEXT PRIMARY KEY,      -- UUID
  session_id    TEXT NOT NULL REFERENCES sessions(id),
  trace_id      TEXT NOT NULL,
  parent_id     TEXT,
  name          TEXT NOT NULL,
  started_at    DATETIME NOT NULL,
  duration_ms   DOUBLE NOT NULL,
  outcome       TEXT NOT NULL,         -- 'ok' | 'error'
  tags          JSON NOT NULL          -- e.g. {"files": 812}
);
CREATE INDEX spans_trace ON spans(trace_id);
CREATE INDEX spans_name_time ON spans(name, started_at);

CREATE TABLE db_snapshots (
  id            INTEGER PRIMARY KEY,
  session_id    TEXT NOT NULL REFERENCES sessions(id),
  taken_at      DATETIME NOT NULL,
  file_bytes    INTEGER NOT NULL,
  wal_bytes     INTEGER NOT NULL,
  row_counts    JSON NOT NULL          -- {"IndexRecord": 48211, "TagRecord": 930, ...}
);

CREATE TABLE timings (
  id            INTEGER PRIMARY KEY,
  session_id    TEXT NOT NULL REFERENCES sessions(id),
  snapshot_id   INTEGER REFERENCES db_snapshots(id),
  window_start  DATETIME NOT NULL,
  window_secs   INTEGER NOT NULL,
  name          TEXT NOT NULL,
  tags          JSON NOT NULL,         -- canonical (sorted-key) JSON
  count         INTEGER NOT NULL,
  sum_ms        DOUBLE NOT NULL,
  min_ms        DOUBLE NOT NULL,
  max_ms        DOUBLE NOT NULL,
  buckets       JSON NOT NULL          -- [n0 … n15], counts per fixed bucket
);
CREATE INDEX timings_name_time ON timings(name, window_start);

CREATE TABLE sql_statements (
  hash           TEXT PRIMARY KEY,     -- 16 hex chars, FNV-1a 64
  kind           TEXT NOT NULL,        -- select | insert | update | delete | begin | commit | other
  normalized_sql TEXT NOT NULL,
  first_seen     DATETIME NOT NULL
);
```

**Spans** are written raw, one row per completed span. Only deliberately created spans (the
indexing pipeline) become spans; SQL statements never do. Volume is low.

**Timings** are aggregated: one row per `(name, tags)` per 60-second window that had activity.
SQL statements are `name = "sql"`, `tags = {"stmt": "<hash>", "conn": "reader"|"writer"}`.

**Buckets** have 16 fixed upper bounds (ms):
`0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100, 250, 500, 1000, 10000, +∞`.
Because the bounds are fixed, bucket counts can be summed across windows and sessions, so
percentiles over any time range are computed correctly. Changing the bounds requires a new
`timings` schema version.

**DB snapshots** are taken during a flush when the flush has data and at least 5 minutes have
passed since the previous snapshot (and once at session start). Each records the main DB file
size, WAL size, and `COUNT(*)` for each table in `SchemaConfiguration.tableNames`, executed on a
read connection. Each `timings` row stores the latest `snapshot_id`, so "latency vs. DB size" is
a direct join.

**SQL normalization** (`SQLNormalizer`):
1. Start from `Statement.sql` (already uses `?` placeholders because
   `publicStatementArguments` is off by default; if the dev flag turns it on, the normalizer
   still works on `sql`, not `expandedSQL`).
2. Collapse whitespace runs to a single space; trim.
3. Collapse placeholder lists `?(\s*,\s*?)+` to `?…` so `IN (?, ?, ?)` of any length shares a key.
4. Hash with FNV-1a 64 → 16 lowercase hex chars. Swift `hashValue` is per-launch randomized and
   must not be used.
5. `kind` is derived from the first keyword.

New hashes are inserted into `sql_statements` at flush (`INSERT OR IGNORE`).

**Retention:** at launch, delete `timings` and `spans` rows older than 90 days. `sessions`,
`db_snapshots`, and `sql_statements` are kept.

## Section 3: Instrumentation Points

### A. Indexing pipeline (Q1)

Each `GRDBIndexService.indexDirectory(at:)` call is one trace. Parent spans are passed
explicitly — not via `@TaskLocal` — because GRDB `write {}` closures run on GRDB's dispatch
queue, where task-locals are not reliably available.

```
index.directory            tags: folder_files, added, removed, unchanged, relocated, created
├─ index.list              diffDirectoryContents: fs enumerate + per-file XID xattr read   tags: files
├─ index.lookup            diffDirectoryContents: getIndexes(matching:)                    tags: rows
├─ index.relocate          write transaction 1                                             tags: rows
├─ index.delete            write transaction 2                                             tags: rows
└─ index.create            write transaction 3                                             tags: rows
```

`index.directory` ends with `outcome: error` if `indexDirectory` throws.

Per-file work is recorded as **timings**, not spans:

| Timing name | Location |
|---|---|
| `fs.xattr.read` | `LocalFileService.indexContents`, around `metadata.retrieveXID` |
| `index.create.xid` | `createIndex(inTransaction:)`, around `assignIndexContentId` (may write an xattr while holding the write lock) |
| `index.create.filenameTags` | `getFilenameData` + `findOrCreateTags` |
| `index.create.insert` | `indx.insert` + tag association inserts |
| `index.create.fetchInfo` | `fetchIndexInfo` (the `IndexInfoRecord` view re-read) |

### B. SQL statements (Q2)

`SQLStatementProfiler` is installed in `GRDBIndexService.configure().prepareDatabase`
**before** the existing `guard db.configuration.readonly else { return }`, so writer
connections are profiled too. It is skipped when `DevFlags.metrics_disable` is set.

- Each statement records `timing("sql", ms: duration, tags: ["stmt": hash, "conn": reader|writer])`.
- Duration is SQLite's profile callback value: wall-clock from first step to reset, which
  includes GRDB row decoding between steps. This is appropriate for "what got slower" but is
  not pure engine time.
- `BEGIN` / `COMMIT` are recorded; commit time reflects WAL pressure.
- The existing, unused `DevFlags.indexer_enableSqlProfiling` is repurposed to additionally log
  each statement's duration to the console for live debugging.

### C. User-facing operations

`AppDispatcher.dispatch(_:)` records `timing("action", tags: ["action": <action case name>])`,
replacing its current `SelfTimer.timeExecution(using:)` call. Combined with B, a slow user
action can be traced to the statement responsible, both as a function of DB size.

## Section 4: Error Handling, Testing, Rollout

### Error handling

Metrics must never affect app behavior.

- All recorder and sink entry points are non-throwing to callers.
- Sink write failure: log once per error kind via `CustomLogger`, drop the batch, no retry.
- `metrics.sqlite` fails to open or migrate: rename to `metrics.sqlite.bad-<timestamp>` and
  create fresh; if that fails too, fall back to `NoopMetricsRecorder` for the session.
- Cardinality guard: at most 5,000 distinct `(name, tags)` keys per window; further new keys
  are counted under `name = "metrics.overflow"`.
- Termination flush has a ~200 ms budget. A crash loses at most ~60 s of aggregates.

### Testing (Quick + Nimble, alongside XCTest)

| Subject | Tests |
|---|---|
| `TimingAggregator` | bucket boundary placement; `drain()` resets; concurrent `record` from many tasks; overflow key |
| `SQLNormalizer` | IN-list collapse; whitespace; `kind` detection; **golden FNV hash values** so key stability regressions fail |
| `SQLiteMetricsSink` | in-memory `DatabaseQueue`: migrations, session/span/timing/snapshot writes, `sql_statements` upsert, retention prune; corrupt-file recovery using a garbage file in a temp dir |
| `Span` | parent/trace id propagation; outcome on error; tags; with a fake recorder buffer |
| Profiler + pipeline integration | `GRDBIndexService(database: DatabaseQueue())` with fixture schema, a `RecordingMetricsRecorder` injected via `FactoryTesting`, `indexDirectory` over a temp folder; assert the five pipeline spans, per-file timings, and `sql` timings |

The test target registers `NoopMetricsRecorder` by default so test runs never write to the
real `metrics.sqlite`.

### Rollout (one commit per step; each builds and passes tests)

1. **Core:** `MetricsRecorder`, `Span`, `TimingAggregator`, `MetricsSink`, `SQLiteMetricsSink`,
   `MetricsFlusher`, `DefaultMetricsRecorder`, `NoopMetricsRecorder`, Factory wiring, tests.
   Coexists with OTel.
2. **Remove OTel:** migrate `SelfTimer` and `AppDispatcher`; remove the `IndexParameters`
   import; delete OTel recorder files, `CodeMeasureKit`, `UnfairQueue`; remove OTel package
   dependencies from the Xcode project.
3. **SQL profiling:** `SQLNormalizer`, `SQLStatementProfiler`, DB snapshots, tests.
4. **Indexing pipeline:** spans and per-file timings, integration test. (Absorbs the
   currently-uncommitted whitespace change in `GRDBIndexer.swift`.)
5. **Docs:** `docs/metrics/queries.sql` (canned analysis queries) and
   `docs/metrics/instruments.md` (how to profile with Instruments and read signposts).

## Analysis Examples (to seed `docs/metrics/queries.sql`)

Percentiles use plain SQL over `json_each(buckets)` so they work in the `sqlite3` CLI without
custom functions.

- **Index pipeline breakdown, last 20 runs:** join `spans` on `trace_id` where the root is
  `index.directory`; pivot child `duration_ms` by `name`.
- **Slowest statements by p95, by DB size:** join `timings` (`name = 'sql'`) to
  `db_snapshots`, bucket by `row_counts->>'IndexRecord'` decile, sum bucket arrays per
  `(stmt, decile)`, compute p95, join `sql_statements` for text.
- **Statements whose p95 grew most** between the earliest and latest month of data.
- **Per-file create cost split:** sum `sum_ms` for `index.create.*` and `fs.xattr.read` per
  session.
