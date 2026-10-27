-- HyperTagBrowser performance queries for metrics.sqlite
--
-- Open with:
--   sqlite3 -header -column ~/Library/Application\ Support/HyperTagBrowser/metrics.sqlite
-- then paste a query. Requires SQLite >= 3.38 (for ->>); macOS 15 ships 3.43+.
--
-- Bucket upper bounds (ms) by index; keep in sync with TimingBuckets.upperBoundsMs.
-- Percentiles below report the bucket upper bound that contains the percentile, so
-- "p95 <= 25ms" means 95% of calls took 25ms or less.


-- 1. Indexing pipeline breakdown, last 20 runs ------------------------------------------
WITH roots AS (
  SELECT id, started_at, duration_ms, tags
  FROM spans
  WHERE name = 'index.directory'
  ORDER BY started_at DESC
  LIMIT 20
)
SELECT
  r.started_at,
  CAST(r.tags ->> 'folder_files' AS INTEGER) AS files,
  CAST(r.tags ->> 'created' AS INTEGER) AS created,
  ROUND(r.duration_ms, 1) AS total_ms,
  ROUND(SUM(CASE WHEN c.name = 'index.list' THEN c.duration_ms END), 1) AS list_ms,
  ROUND(SUM(CASE WHEN c.name = 'index.lookup' THEN c.duration_ms END), 1) AS lookup_ms,
  ROUND(SUM(CASE WHEN c.name = 'index.relocate' THEN c.duration_ms END), 1) AS relocate_ms,
  ROUND(SUM(CASE WHEN c.name = 'index.delete' THEN c.duration_ms END), 1) AS delete_ms,
  ROUND(SUM(CASE WHEN c.name = 'index.create' THEN c.duration_ms END), 1) AS create_ms
FROM roots r
JOIN spans c ON c.parent_id = r.id
GROUP BY r.id
ORDER BY r.started_at DESC;


-- 2. Per-file indexing cost split, per session ------------------------------------------
SELECT
  s.started_at AS session,
  t.name,
  SUM(t.count) AS calls,
  ROUND(SUM(t.sum_ms), 1) AS total_ms,
  ROUND(SUM(t.sum_ms) / SUM(t.count), 3) AS avg_ms,
  ROUND(MAX(t.max_ms), 1) AS max_ms
FROM timings t
JOIN sessions s ON s.id = t.session_id
WHERE t.name IN ('fs.xattr.read', 'fs.xattr.assign') OR t.name LIKE 'index.create.%'
GROUP BY s.id, t.name
ORDER BY s.started_at DESC, total_ms DESC;


-- 3. Slowest SQL statements by p95, per 10k-row band of app_content_indices -------------
WITH bounds(idx, upper_ms) AS (
  VALUES (0, 0.05), (1, 0.1), (2, 0.25), (3, 0.5), (4, 1), (5, 2.5), (6, 5), (7, 10),
         (8, 25), (9, 50), (10, 100), (11, 250), (12, 500), (13, 1000), (14, 10000),
         (15, 1e999)
),
hist AS (
  SELECT
    t.tags ->> 'stmt' AS stmt,
    (CAST(d.row_counts ->> 'app_content_indices' AS INTEGER) / 10000) * 10000 AS rows_band,
    CAST(b.key AS INTEGER) AS idx,
    SUM(b.value) AS n
  FROM timings t
  JOIN db_snapshots d ON d.id = t.snapshot_id
  JOIN json_each(t.buckets) b
  WHERE t.name = 'sql'
  GROUP BY 1, 2, 3
),
cum AS (
  SELECT stmt, rows_band, idx,
    SUM(n) OVER (PARTITION BY stmt, rows_band ORDER BY idx) AS running,
    SUM(n) OVER (PARTITION BY stmt, rows_band) AS total
  FROM hist
),
p95 AS (
  SELECT stmt, rows_band, total, MIN(idx) AS idx
  FROM cum
  WHERE running >= 0.95 * total
  GROUP BY stmt, rows_band
)
SELECT
  p.rows_band,
  p.total AS calls,
  b.upper_ms AS p95_le_ms,
  q.kind,
  substr(q.normalized_sql, 1, 120) AS sql
FROM p95 p
JOIN bounds b ON b.idx = p.idx
LEFT JOIN sql_statements q ON q.hash = p.stmt
ORDER BY p.rows_band DESC, b.upper_ms DESC, p.total DESC
LIMIT 50;


-- 4. Statements whose p95 grew most as the database grew --------------------------------
WITH bounds(idx, upper_ms) AS (
  VALUES (0, 0.05), (1, 0.1), (2, 0.25), (3, 0.5), (4, 1), (5, 2.5), (6, 5), (7, 10),
         (8, 25), (9, 50), (10, 100), (11, 250), (12, 500), (13, 1000), (14, 10000),
         (15, 1e999)
),
hist AS (
  SELECT
    t.tags ->> 'stmt' AS stmt,
    (CAST(d.row_counts ->> 'app_content_indices' AS INTEGER) / 10000) * 10000 AS rows_band,
    CAST(b.key AS INTEGER) AS idx,
    SUM(b.value) AS n
  FROM timings t
  JOIN db_snapshots d ON d.id = t.snapshot_id
  JOIN json_each(t.buckets) b
  WHERE t.name = 'sql'
  GROUP BY 1, 2, 3
),
cum AS (
  SELECT stmt, rows_band, idx,
    SUM(n) OVER (PARTITION BY stmt, rows_band ORDER BY idx) AS running,
    SUM(n) OVER (PARTITION BY stmt, rows_band) AS total
  FROM hist
),
p95 AS (
  SELECT stmt, rows_band, MIN(idx) AS idx
  FROM cum
  WHERE running >= 0.95 * total
  GROUP BY stmt, rows_band
),
ranked AS (
  SELECT stmt, rows_band, idx,
    ROW_NUMBER() OVER (PARTITION BY stmt ORDER BY rows_band) AS first_rank,
    ROW_NUMBER() OVER (PARTITION BY stmt ORDER BY rows_band DESC) AS last_rank
  FROM p95
)
SELECT
  f.rows_band AS from_rows,
  bf.upper_ms AS from_p95_le_ms,
  l.rows_band AS to_rows,
  bl.upper_ms AS to_p95_le_ms,
  l.idx - f.idx AS buckets_grown,
  substr(q.normalized_sql, 1, 120) AS sql
FROM ranked f
JOIN ranked l ON l.stmt = f.stmt AND l.last_rank = 1
JOIN bounds bf ON bf.idx = f.idx
JOIN bounds bl ON bl.idx = l.idx
LEFT JOIN sql_statements q ON q.hash = f.stmt
WHERE f.first_rank = 1 AND l.rows_band > f.rows_band
ORDER BY buckets_grown DESC
LIMIT 25;


-- 5. User actions: average latency per 10k-row band -------------------------------------
SELECT
  t.tags ->> 'action' AS action,
  (CAST(d.row_counts ->> 'app_content_indices' AS INTEGER) / 10000) * 10000 AS rows_band,
  SUM(t.count) AS calls,
  ROUND(SUM(t.sum_ms) / SUM(t.count), 2) AS avg_ms,
  ROUND(MAX(t.max_ms), 1) AS max_ms
FROM timings t
JOIN db_snapshots d ON d.id = t.snapshot_id
WHERE t.name = 'action'
GROUP BY 1, 2
ORDER BY avg_ms DESC;


-- 6. Database growth over time ---------------------------------------------------------
SELECT
  taken_at,
  CAST(row_counts ->> 'app_content_indices' AS INTEGER) AS indices,
  CAST(row_counts ->> 'app_content_tag_items' AS INTEGER) AS tag_items,
  ROUND(file_bytes / 1048576.0, 1) AS file_mb,
  ROUND(wal_bytes / 1048576.0, 1) AS wal_mb
FROM db_snapshots
ORDER BY taken_at;
