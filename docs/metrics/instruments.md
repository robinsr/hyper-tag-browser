# Profiling HyperTagBrowser with Instruments

Every metrics span (`index.directory`, `index.list`, …) is also an `os_signpost` interval in
the **Points of Interest** category, under the app's bundle identifier. Use Instruments for
"what is happening right now, and why"; use `metrics.sqlite` (`docs/metrics/queries.sql`) for
trends across sessions.

## Record a trace

1. In Xcode, choose **Product → Profile** (⌘I). This builds Release and opens Instruments.
2. Pick the **Time Profiler** template. It includes a *Points of Interest* track.
   - For signposts only, choose **Blank** and add the **os_signpost** and
     **Points of Interest** instruments with the **+** button.
3. Press record. In the app, index a folder (or do whatever feels slow).
4. Stop recording.

## Read it

- **Points of Interest track:** one bar per span. `index.directory` contains `index.list`,
  `index.lookup`, `index.relocate`, `index.delete`, `index.create` in order. The bar length is
  the duration.
- **Drill into a slow bar:** drag-select its time range in the timeline. The **Time Profiler**
  call tree below then shows only CPU samples from that range. Turn on **Invert Call Tree**
  and **Hide System Libraries** to see which of the app's functions dominate.
- **Waiting, not computing:** if a bar is long but has few CPU samples, the thread was blocked
  (disk I/O, xattrs, a lock, SQLite waiting on the writer). Add the **System Call Trace** or
  **File Activity** instrument to see what it waited on.

## What isn't in Instruments

Per-file and per-SQL-statement timings are aggregated, not signposted, to keep traces readable.
For those, see queries 2–4 in `docs/metrics/queries.sql`. For live per-statement durations,
enable the **Enable SQL Profiling** dev flag, which logs each statement's time to the console.
