package queries_test

import (
	"context"
	"testing"

	"github.com/robinsr/taggedfilebrowser/server/db/queries"
	"github.com/robinsr/taggedfilebrowser/server/db/queries/testutil"
)

func TestListFileHistory(t *testing.T) {
	db := testutil.NewTestDB(t)
	entries, err := queries.ListFileHistory(context.Background(), db, "file:abc001")
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 2 {
		t.Fatalf("got %d history entries, want 2", len(entries))
	}
	// ordered by timestamp DESC, so entry 2 is first
	if entries[0].ColumnName != "location" {
		t.Errorf("first entry column: got %q, want location", entries[0].ColumnName)
	}
	if entries[1].FsStatus != "synced" {
		t.Errorf("second entry fsStatus: got %q, want synced", entries[1].FsStatus)
	}
}
