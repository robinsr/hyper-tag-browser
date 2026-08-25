-- concatGroup: aggregate like GROUP_CONCAT with ',' separator
CREATE TEMP TABLE t(v TEXT);
INSERT INTO t VALUES ('a'), ('b'), ('c');
SELECT concatGroup(v) FROM t;
-- expected: a,b,c

-- textConcat: concatenate args with no separator
SELECT textConcat('hello', ' ', 'world');
-- expected: hello world

-- textJoin: first arg is separator
SELECT textJoin('-', 'a', 'b', 'c');
-- expected: a-b-c

-- hashId: deterministic FNV-1a hex of concatenated args
SELECT length(hashId('foo', 'bar')) = 16;
-- expected: 1  (always 16 hex chars)
SELECT hashId('foo') = hashId('foo');
-- expected: 1  (deterministic)
SELECT hashId('foo') = hashId('bar');
-- expected: 0  (different inputs differ)
