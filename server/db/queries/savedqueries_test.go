package queries_test

import (
	"context"
	"testing"

	"github.com/robinsr/taggedfilebrowser/server/db/queries"
	"github.com/robinsr/taggedfilebrowser/server/db/queries/testutil"
)

func TestGetSavedQuery_Found(t *testing.T) {
	db := testutil.NewTestDB(t)
	sq, err := queries.GetSavedQuery(context.Background(), db, "query:sq001")
	if err != nil {
		t.Fatal(err)
	}
	if sq == nil {
		t.Fatal("expected saved query, got nil")
	}
	if sq.Name != "My Vacation Photos" {
		t.Errorf("name: got %q, want My Vacation Photos", sq.Name)
	}
	if sq.Query == "" {
		t.Error("expected non-empty query JSON")
	}
}

func TestListSavedQueries(t *testing.T) {
	db := testutil.NewTestDB(t)
	list, err := queries.ListSavedQueries(context.Background(), db)
	if err != nil {
		t.Fatal(err)
	}
	if len(list) != 1 {
		t.Errorf("got %d saved queries, want 1", len(list))
	}
}
