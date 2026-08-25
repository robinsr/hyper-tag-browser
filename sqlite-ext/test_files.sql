-- fileExists: 1 for existing path, 0 for missing
SELECT fileExists('/etc/hosts');
-- expected: 1
SELECT fileExists('/this/does/not/exist');
-- expected: 0

-- fileExistsIn: folder + filename
SELECT fileExistsIn('/etc/', 'hosts');
-- expected: 1
SELECT fileExistsIn('/etc/', 'nope.txt');
-- expected: 0

-- fileSize: byte count
SELECT fileSize('/etc/hosts') > 0;
-- expected: 1
SELECT fileSize('/this/does/not/exist') IS NULL;
-- expected: 1

-- xattr: read macOS extended attribute (com.apple.quarantine is common on downloaded files)
-- This will return NULL for /etc/hosts since it has no quarantine xattr — that's correct.
SELECT xattr('/etc/hosts', 'com.apple.quarantine') IS NULL;
-- expected: 1

-- fileContents: returns BLOB
SELECT length(fileContents('/etc/hosts')) > 0;
-- expected: 1
SELECT fileContents('/this/does/not/exist') IS NULL;
-- expected: 1
