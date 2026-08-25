-- regexpMatch: returns 1 if pattern matches, 0 if not
SELECT regexpMatch('hello world', 'world');
-- expected: 1
SELECT regexpMatch('hello world', '^foo');
-- expected: 0

-- regexpCapture: extract capture group by index (0 = whole match)
-- Note: POSIX ERE syntax — to exclude ] from a char class, put it immediately
-- after [^ rather than using \] (which has no special meaning in POSIX char classes).
SELECT regexpCapture('file [tag1]', '\[([^]]+)\]', 1);
-- expected: tag1
SELECT regexpCapture('hello', '^(he)(ll)', 2);
-- expected: ll

-- regexpReplace: replace first match
SELECT regexpReplace('hello world', 'world', 'earth');
-- expected: hello earth
SELECT regexpReplace('no match here', 'xyz', 'ABC');
-- expected: no match here
