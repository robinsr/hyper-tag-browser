// server/db/queries/testutil/fixtures.go
package testutil

import (
	"database/sql"
	"testing"

	_ "modernc.org/sqlite"
)

// NewTestDB returns an in-memory SQLite database pre-populated with test data
// matching the HyperTagBrowser schema.
func NewTestDB(t *testing.T) *sql.DB {
	t.Helper()
	db, err := sql.Open("sqlite", ":memory:")
	if err != nil {
		t.Fatal(err)
	}

	schema := `
    CREATE TABLE app_content_indices (
        id TEXT PRIMARY KEY,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        volume TEXT NOT NULL DEFAULT 'Macintosh HD',
        type TEXT NOT NULL,
        size INTEGER NOT NULL DEFAULT 0,
        created DATETIME NOT NULL,
        modified DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        comment TEXT NOT NULL DEFAULT '',
        visibility TEXT NOT NULL DEFAULT 'normal'
    );
    CREATE TABLE app_content_tags (
        id TEXT PRIMARY KEY,
        tagType TEXT NOT NULL DEFAULT 'tag',
        tagValue TEXT NOT NULL,
        entryType TEXT NOT NULL DEFAULT 'normal',
        relatedId TEXT REFERENCES app_content_tags(id) ON DELETE CASCADE,
        filterValue TEXT GENERATED ALWAYS AS (tagType || '|' || tagValue) VIRTUAL
    );
    CREATE TABLE app_content_tag_items (
        id TEXT PRIMARY KEY,
        tagId TEXT NOT NULL REFERENCES app_content_tags(id),
        contentId TEXT NOT NULL REFERENCES app_content_indices(id),
        UNIQUE(tagId, contentId)
    );
    CREATE TABLE app_bookmarks (
        id TEXT PRIMARY KEY,
        created DATETIME NOT NULL,
        contentId TEXT REFERENCES app_content_indices(id) ON DELETE CASCADE
    );
    CREATE TABLE app_workqueues (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created DATETIME NOT NULL
    );
    CREATE TABLE app_workqueue_items (
        id TEXT PRIMARY KEY,
        queueId TEXT NOT NULL REFERENCES app_workqueues(id),
        contentId TEXT NOT NULL REFERENCES app_content_indices(id),
        created DATETIME NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        UNIQUE(queueId, contentId)
    );
    CREATE TABLE app_saved_content_queries (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        query TEXT NOT NULL,
        createdAt DATETIME NOT NULL,
        updatedAt DATETIME NOT NULL
    );
    CREATE TABLE app_content_indices_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp DATETIME NOT NULL,
        fsStatus TEXT NOT NULL DEFAULT 'pending',
        indexId TEXT NOT NULL,
        indexType TEXT,
        columnName TEXT NOT NULL,
        newValue TEXT NOT NULL,
        oldValue TEXT NOT NULL
    );
    CREATE VIEW app_content_tag_item_values AS
        SELECT
            ti.id, ti.tagId, ti.contentId,
            t.tagType || '|' || t.tagValue AS value
        FROM app_content_tag_items ti
        JOIN app_content_tags t ON ti.tagId = t.id;
    CREATE VIEW app_content_tag_items_joined AS
        SELECT
            ti.contentId,
            group_concat(':' || t.tagType || '|' || t.tagValue || ':', '') AS tagString,
            count(*) AS tagCount
        FROM app_content_tags t
        JOIN app_content_tag_items ti ON ti.tagId = t.id
        GROUP BY ti.contentId;
    `

	if _, err := db.Exec(schema); err != nil {
		t.Fatal(err)
	}

	seed := `
    INSERT INTO app_content_indices VALUES
        ('file:abc001', CURRENT_TIMESTAMP, 'photo.jpg', '/Users/ryan/Pictures/', 'Macintosh HD',
         'public.jpeg', 2048000, '2024-01-15 10:00:00', '2024-01-15 10:00:00', '', 'normal'),
        ('file:abc002', CURRENT_TIMESTAMP, 'notes.txt', '/Users/ryan/Documents/', 'Macintosh HD',
         'public.plain-text', 4096, '2024-02-20 12:30:00', '2024-03-01 09:00:00', 'meeting notes', 'normal');

    INSERT INTO app_content_tags (id, tagType, tagValue, entryType, relatedId) VALUES
        ('tag:t001', 'tag', 'vacation', 'normal', NULL),
        ('tag:t002', 'artist', 'ryan', 'normal', NULL);

    INSERT INTO app_content_tag_items VALUES
        ('tagitem:i001', 'tag:t001', 'file:abc001'),
        ('tagitem:i002', 'tag:t002', 'file:abc001');

    INSERT INTO app_bookmarks VALUES
        ('bookmark:b001', '2024-01-16 08:00:00', 'file:abc001');

    INSERT INTO app_workqueues VALUES
        ('queue:q001', 'To Review', '2024-01-01 00:00:00');

    INSERT INTO app_workqueue_items VALUES
        ('queueitem:qi001', 'queue:q001', 'file:abc001', '2024-01-16 09:00:00', 0);

    INSERT INTO app_saved_content_queries VALUES
        ('query:sq001', 'My Vacation Photos',
         '{"root":"/Users/ryan/Pictures","mode":{"type":"immediate"},"types":["images"],"visibility":"normal","tagsMatching":{"filterOpr":"and","filters":[]},"nameMatching":{"filterOpr":"and","values":[]},"excludeContent":{"filterOpr":"and","values":[]},"sortBy":"nameAsc","limit":100,"offset":0}',
         '2024-03-01 10:00:00', '2024-03-01 10:00:00');

    INSERT INTO app_content_indices_history VALUES
        (1, '2024-03-01 10:00:00', 'synced', 'file:abc001', 'public.jpeg', 'name', 'photo_new.jpg', 'photo.jpg'),
        (2, '2024-03-02 11:00:00', 'pending', 'file:abc001', 'public.jpeg', 'location', '/Users/ryan/Pictures/', '/Users/ryan/Desktop/');
    `

	if _, err := db.Exec(seed); err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() { db.Close() })
	return db
}
