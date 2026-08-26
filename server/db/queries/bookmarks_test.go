package queries_test

import (
	"context"
	"testing"

	"github.com/robinsr/taggedfilebrowser/server/db/queries"
	"github.com/robinsr/taggedfilebrowser/server/db/queries/testutil"
)

func TestListBookmarks(t *testing.T) {
	db := testutil.NewTestDB(t)
	bookmarks, err := queries.ListBookmarks(context.Background(), db)
	if err != nil {
		t.Fatal(err)
	}
	if len(bookmarks) != 1 {
		t.Fatalf("got %d bookmarks, want 1", len(bookmarks))
	}
	if bookmarks[0].ID != "bookmark:b001" {
		t.Errorf("id: got %q, want bookmark:b001", bookmarks[0].ID)
	}
	if bookmarks[0].File == nil {
		t.Fatal("expected file, got nil")
	}
	if bookmarks[0].File.ID != "file:abc001" {
		t.Errorf("file.id: got %q, want file:abc001", bookmarks[0].File.ID)
	}
}
