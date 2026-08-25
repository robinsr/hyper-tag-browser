-- Integration test against a real HyperTagBrowser database.
-- Load the extension first: .load ~/.local/lib/htb_ext.dylib
-- Then open the DB: litecli /path/to/HyperTagBrowser.db

-- This view uses concatGroup and previously caused OperationalError
SELECT * FROM tag_string LIMIT 5;

-- TagRecord uses textJoin to build filterValue
SELECT id, filterValue FROM app_tags LIMIT 5;

-- fileExistsIn against real indexed files
SELECT name, fileExistsIn(location, name) AS on_disk
FROM app_content_indices
LIMIT 10;
