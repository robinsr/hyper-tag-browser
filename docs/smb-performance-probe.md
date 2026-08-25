# SMB Network Drive Performance Probe

## Background

HyperTagBrowser's indexing pipeline (`indexContents` → `retrieveXID` / `assignNewXID`) is
noticeably slower on SMB network shares than on local APFS volumes. Two likely bottlenecks were
identified during initial analysis:

1. **Extended attribute (xattr) I/O** — `retrieveXID` and `assignNewXID` call into the XAttr
   library for every file. On SMB, xattrs are implemented as named alternate data streams, which
   require separate network round-trips and vary widely in NAS/Samba support.

2. **Per-file `stat` cost in the enumerator loop** — `FileManager.enumerator(includingPropertiesForKeys:)`
   pre-fetches `URLResourceKeys` at enumerate-time, but `resourceValues(forKeys:)` can still
   trigger additional stat calls per file, and each round-trip is amplified by network latency.

This probe instruments both sites to produce per-file timing data visible in Instruments, so we
can measure the actual contribution of each before committing to an architectural fix.

---

## What Was Instrumented

All instrumentation is wrapped in `#if DEBUG` and labeled as throwaway. Remove before shipping.

### `SMBProbe.xattr` signpost category
File: `HyperTagBrowser/App/Services/System/MetadataService.swift`

| Interval name  | Covers |
|----------------|--------|
| `xattr-read`   | Full body of `retrieveXID` — two xattr syscalls: `extendedAttributeNames()` + `extendedAttributeValues(forNames:)` |
| `xattr-write`  | Full body of `assignNewXID` — one xattr syscall: `setExtendedAttribute(data:forName:)` |

### `SMBProbe.indexer` signpost category
File: `HyperTagBrowser/App/Services/LocalFiles/LocalFileService.swift`

| Interval name | Covers |
|---------------|--------|
| `loop-body`   | Full iteration of the `indexContents` while-loop: enumerator advance, `resourceValues` stat, type filter, plus the nested `xattr-read` or `xattr-write` call |

Because `loop-body` nests the xattr intervals, you can compute:

```
enumerator-overhead ≈ loop-body − xattr-read (or xattr-write)
```

---

## Running the Probe

### Prerequisites

- Build the **Debug** scheme in Xcode (signposts are compiled out in Release).
- Have a test directory of ~100 files accessible both locally and via SMB.
- SMB share mounted at `/Volumes/<share-name>/`.

### Step-by-step: Instruments

1. **Open Instruments** — Product → Profile (⌘I) in Xcode, or launch `/Applications/Instruments.app`.
2. Choose the **Blank** template (gives you a clean slate).
3. Add instruments:
   - **os_signpost** — shows the three interval types as lanes
   - **File Activity** — shows underlying `open()`, `getxattr()`, `setxattr()` syscalls with per-call timing
   - **Time Profiler** — optional; useful for seeing CPU time if the bottleneck isn't pure I/O wait
4. In the target selector at top-left, choose **HyperTagBrowser.app**.
5. Click **Record** (red button), then trigger an index of your test directory from within the app.
6. Stop recording after the index completes.

### Reading the signpost lane

- Expand **os_signpost → com.robinsr.hypertag**.
- You'll see three categories: `SMBProbe.xattr` and `SMBProbe.indexer`.
- Each interval instance carries the filename as its message string, making it easy to correlate
  with the File Activity trace below.

### Comparing local vs. SMB

Run two separate Instruments sessions — one with a local APFS path, one with the SMB mount — and
save both `.trace` files. In Instruments, use **File → Open** on both and compare:

- Median `xattr-read` duration per file
- Median `xattr-write` duration per file
- Median `loop-body` duration per file
- Ratio of xattr time to total loop-body time

A rough heuristic: if xattr accounts for >70% of `loop-body` on SMB but <20% locally, that's
strong evidence the xattr path is the bottleneck worth eliminating.

---

## Interpreting Results

### xattr dominates on SMB → skip or batch xattrs

If xattr intervals are long on SMB, the fix is to make the xattr dependency optional:

- **Option A (skip):** Index files by inode + mtime instead of a persisted xattr ID. This avoids
  all xattr I/O but requires re-thinking ID stability across renames.
- **Option B (batch):** Fetch all xattrs in a single `listxattr`/`getxattr` loop before entering
  the indexer, amortizing round-trips. Benefit depends on SMB server support for batching.
- **Option C (async write):** Write xattrs asynchronously after inserting the DB record. Initial
  indexing uses a temporary ID; the xattr is written as a background task.

### Enumerator overhead dominates → prefetch more aggressively

If `loop-body` is long but xattr intervals are short, the bottleneck is in `resourceValues` / the
enumerator advance. Possible fixes:

- Pre-resolve all resource keys at enumerator creation time (the `includingPropertiesForKeys`
  argument) rather than calling `resourceValues(forKeys:)` per file.
- Use `NSMetadataQuery` to enumerate remote volumes; it uses Spotlight's already-cached metadata
  rather than per-file stat calls.

### Neither dominates → network latency floor

If both intervals are long and roughly equal, the issue may simply be the per-file network round-
trip floor. In that case, pipelining (enumerating on a background thread while the main indexer
processes a queue) or pre-caching the directory listing before entering `indexContents` would help
more than xattr removal.

---

## Cleanup

Once the probe run is complete and conclusions are drawn, remove:

- The `#if DEBUG` / `import os` block and `smbProbe` property from `MetadataService.swift`
- The same blocks from `LocalFileService.swift`
- The three `#if DEBUG` signpost intervals in their respective methods

All locations are marked with `// SMB performance probe — throwaway instrumentation, remove before ship`.
